using ConsoliSQL.Models;
using HtmlAgilityPack;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using QuickGraph;
using QuickGraph.Algorithms;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;

namespace ConsoliSQL.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return View();
        }

        const string BEGIN_TRAN = "BEGIN TRAN";
        const string END_TRAN = "ROLLBACK";

        const string BATCH_SEPERATOR = "GO";

        const string WINDOWS_LINE_ENDING = "\r\n";
        const string UNIX_LINE_ENDING = "\n";

        const string ERROR_MESSAGE_FILES = "No files have been selected.";

        [HttpPost]
        public ActionResult Index(Home model)
        {
            if (model.Files == null || (model.Files.Count() == 1 && model.Files.First() == null))
            {
                ModelState.AddModelError("Files", ERROR_MESSAGE_FILES);
            }

            if (ModelState.IsValid)
            {
                var scriptFiles = new HashSet<ScriptFile>();

                foreach (var file in model.Files)
                {
                    var sqlObjects = new HashSet<SqlObject>();
                    var scriptFile = new ScriptFile();
                    var html = new HtmlDocument();

                    using (var reader = new StreamReader(file.InputStream))
                    using (var stringReader = new StringReader(reader.ReadToEnd()))
                    {
                        var parser = new TSql140Parser(false);
                        IList<ParseError> parseErrors;
                        var parseContent = (TSqlScript)parser.Parse(stringReader, out parseErrors);

                        foreach (var batch in parseContent.Batches)
                        {
                            foreach (var statement in batch.Statements)
                            {
                                Helpers.FindDependencies(statement, sqlObjects, scriptFile);
                            }
                        }

                        scriptFile.FileName = Path.GetFileName(file.FileName);
                        scriptFile.Creates = sqlObjects.Where(x => x.IsCreate);
                        scriptFile.DependsOn = sqlObjects.Where(x => !x.IsCreate);
                        scriptFile.ParseErrors = parseErrors.Select(x => $"{x.Message} Line: {x.Line}");

                        var sqlStatement = new StringBuilder();
                        if (model.PrependDrops)
                        {
                            foreach (var createObj in scriptFile.Creates.Where(x => !x.Ignore && !x.IsSystemObject))
                            {
                                if (createObj.Type == SqlObjectType.Index)
                                {
                                    sqlStatement.AppendFormat("IF EXISTS(SELECT [index_id] FROM [sys].[indexes] WHERE [name] = '{1}' AND [object_id] = OBJECT_ID('{2}', 'U')){0}", Environment.NewLine, createObj.Name, createObj.LinkObject.Name);
                                    sqlStatement.AppendFormat("DROP INDEX {1} ON {2}{0}", Environment.NewLine, createObj.Name, createObj.LinkObject.Name);
                                    sqlStatement.AppendFormat("GO{0}{0}", Environment.NewLine);
                                }
                                else
                                {
                                    sqlStatement.AppendFormat("IF OBJECT_ID('{1}', '{2}') IS NOT NULL{0}", Environment.NewLine, createObj.Name, createObj.Type.GetSqlObjectType());
                                    sqlStatement.AppendFormat("DROP {1} {2}{0}", Environment.NewLine, createObj.Type.GetSqlObjectKeyword(), createObj.Name);
                                    sqlStatement.AppendFormat("GO{0}{0}", Environment.NewLine);
                                }
                            }
                        }
                        
                        var indiciesToObjects = scriptFile.Creates.Union(scriptFile.DependsOn).Distinct().ToDictionary(x => x.NameTokenIndex, x => x);
                        for (int i = parseContent.FirstTokenIndex; i <= parseContent.LastTokenIndex; i++)
                        {
                            var token = parseContent.ScriptTokenStream[i];
                            if (token.Text != null)
                            {
                                sqlStatement.Append(token.Text);
                                
                                if (indiciesToObjects.ContainsKey(i))
                                {
                                    var span = html.CreateElement("mark");
                                    if (indiciesToObjects[i].IsSystemObject)
                                    {
                                        span.SetAttributeValue("style", "background-color: #E0E0E0;");
                                    }
                                    else if (indiciesToObjects[i].Ignore)
                                    {
                                        span.SetAttributeValue("style", "background-color: #A1887F;");
                                    }
                                    else
                                    {
                                        span.SetAttributeValue("style", "background-color: #FFF176;");
                                    }

                                    span.InnerHtml = token.Text;
                                    
                                    html.DocumentNode.AppendChild(span);
                                }
                                else
                                {
                                    html.DocumentNode.AppendChild(html.CreateTextNode(token.Text));
                                }
                            }
                        }

                        sqlStatement.AppendLine();

                        if (model.AppendGo)
                        {
                            sqlStatement.AppendLine(BATCH_SEPERATOR);
                            html.DocumentNode.AppendChild(html.CreateTextNode($"{Environment.NewLine}{BATCH_SEPERATOR}"));
                        }
                        
                        scriptFile.Content = sqlStatement.ToString();
                        scriptFile.Overview = html.DocumentNode.OuterHtml;

                        scriptFiles.Add(scriptFile);
                    }
                }
                
                var dependencyGraph = new AdjacencyGraph<ScriptFile, SEdge<ScriptFile>>();
                foreach (var scriptFile in scriptFiles)
                {
                    dependencyGraph.AddVertex(scriptFile);
                }
                
                foreach (var scriptFile in scriptFiles)
                {
                    foreach (var depObj in scriptFile.FilteredDependsOn())
                    {
                        var createObj = scriptFiles.SelectMany(x => x.Creates.Where(y => y.IsCreate && !y.Ignore && y.Type == depObj.Type && y.Name.Equals(depObj.Name, model.CaseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase))).FirstOrDefault();

                        if (createObj != null && !dependencyGraph.ContainsEdge(createObj.File, scriptFile) && !createObj.File.Equals(scriptFile))
                        {
                            dependencyGraph.AddEdge(new SEdge<ScriptFile>(createObj.File, scriptFile));
                        }
                    }
                }
                
                var dot = Visualizer.ToDotNotation(dependencyGraph);
                var orderedScripts = dependencyGraph.TopologicalSort();
                var script = new StringBuilder();

                if (model.WrapTransaction)
                {
                    script.AppendLine(BEGIN_TRAN);
                }

                foreach (var scriptFile in orderedScripts)
                {
                    script.AppendLine(scriptFile.Content);
                }

                if (model.WrapTransaction)
                {
                    script.AppendLine(END_TRAN);
                }

                var output = script.ToString();
                if (model.NormaliseLineEndings)
                {
                    output = output.Replace(WINDOWS_LINE_ENDING, UNIX_LINE_ENDING).Replace(UNIX_LINE_ENDING, WINDOWS_LINE_ENDING);
                }

                var filteredScriptFiles = scriptFiles.Select(x => 
                {
                    x.Creates = x.FilteredCreates().GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                    x.DependsOn = x.UniqueFilteredDependsOn(model.CaseSensitive).GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                    return x;
                });

                /*
                 * Display warning if multiple scripts are creating duplicate object (name==name && type==type)
                 * Add code for Prepend IF EXISTS DROP
                 * Improve parse time
                 * Add pop out graph
                */

                return View("Consolidated", new Consolidated { Script = output, DotNotation = dot, ScriptFiles = filteredScriptFiles });
            }

            return View();
        }
    }
}