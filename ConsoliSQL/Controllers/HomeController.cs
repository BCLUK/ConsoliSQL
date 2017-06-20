using ConsoliSQL.Models;
using HtmlAgilityPack;
using Microsoft.AspNet.SignalR;
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
        const string XACT_ABORT = "SET XACT_ABORT ON";
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
                var count = 0;
                var filesCount = model.Files.Count();

                foreach (var file in model.Files)
                {
                    Hubs.ConsolidateProgressHub.ReportProgress(User.Identity.Name, Path.GetFileName(file.FileName), (double)++count / filesCount * 100);

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
                                var isDescendant = false;
                                Helpers.FindDependencies(statement, sqlObjects, scriptFile, ref isDescendant);
                            }
                        }

                        // The reason we don't filter out ignored/system/descendant objects here is so we can mark them up in the document view
                        scriptFile.FileName = Path.GetFileName(file.FileName);
                        scriptFile.Creates = sqlObjects.Where(x => x.IsCreate);
                        scriptFile.DependsOn = sqlObjects.Where(x => !x.IsCreate);
                        scriptFile.ParseErrors = parseErrors.Select(x => $"{x.Message} Line: {x.Line}");

                        var sqlStatement = new StringBuilder();
                        if (model.PrependDrops && !model.DropsAtTop)
                        {
                            foreach (var createObj in scriptFile.Creates.Where(x => !x.Ignore && !x.IsSystemObject && !x.IsDescendant))
                            {
                                sqlStatement.Append(createObj.ScriptDropStatement());
                            }
                        }
                        
                        var tokenBlacklist = new Dictionary<int, DropStatementException>();
                        if (model.DropsAtTop)
                        {
                            foreach (var dependObj in scriptFile.DependsOn)
                            {
                                // Make sure it's not a drop statement inside a procedure, e.g. dropping a temporary table
                                if (dependObj.IsDrop && !dependObj.IsDescendant)
                                {
                                    var statement = new StringBuilder();
                                    for (var i = dependObj.Fragment.FirstTokenIndex; i <= dependObj.Fragment.LastTokenIndex; i++)
                                    {
                                        statement.Append(dependObj.Fragment.ScriptTokenStream[i].Text ?? "");
                                    }
                                    
                                    tokenBlacklist.Add(dependObj.Fragment.FirstTokenIndex, new DropStatementException(dependObj.Fragment.LastTokenIndex - dependObj.Fragment.FirstTokenIndex, statement.ToString()));
                                }
                            }
                        }
                        

                        var indiciesToObjects = scriptFile.Creates.Union(scriptFile.DependsOn).GroupBy(x => x.NameTokenIndex).Select(x => x.First()).ToDictionary(x => x.NameTokenIndex, x => x);
                        for (int i = parseContent.FirstTokenIndex; i <= parseContent.LastTokenIndex; i++)
                        {
                            if (tokenBlacklist.ContainsKey(i))
                            {
                                var statement = tokenBlacklist[i].Statement;
                                var escapedStatement = Microsoft.SqlServer.Management.SqlParser.Parser.EscapeSequence.SingleQuotedEscapeSequence.Escape(statement);

                                sqlStatement.AppendFormat("/* {0} */ PRINT {1} - Commented out by ConsoliSQL'{2}", statement, escapedStatement.TrimEnd('\''), Environment.NewLine);
                                i += tokenBlacklist[i].TokenLength;
                                continue;
                            }

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
                        // Search all script files for create object that isn't ignored (temporary table), is the same type as @depObj, has the same name as @depObj & isn't a descendant object
                        var createObj = scriptFiles.SelectMany(x => x.Creates.Where(y => y.IsCreate && !y.Ignore && y.Type.IsEqualTo(depObj.Type) && y.Name.Equals(depObj.Name, model.CaseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase) && !y.IsDescendant)).FirstOrDefault();

                        // If a script file was found and a link between @scriptFile to @createObj doesn't already exist, and @createObj doesn't equal @scriptFile
                        if (createObj != null && !dependencyGraph.ContainsEdge(createObj.File, scriptFile) && !createObj.File.Equals(scriptFile))
                        {
                            dependencyGraph.AddEdge(new SEdge<ScriptFile>(createObj.File, scriptFile));
                        }
                    }
                }

                if (model.AllowCircularDependies && !dependencyGraph.IsDirectedAcyclicGraph())
                {
                    var parallelEdges = dependencyGraph.Edges.Where(x => dependencyGraph.ContainsEdge(x.Target, x.Source)).ToList();
                    foreach (var edge in parallelEdges)
                    {
                        parallelEdges.RemoveAll(x => x.Source == edge.Target && x.Target == x.Source);
                    }

                    dependencyGraph.RemoveEdgeIf(x => parallelEdges.Contains(x));
                }

                if (!dependencyGraph.IsDirectedAcyclicGraph())
                {
                    var parallelEdges = dependencyGraph.Edges.Where(x => dependencyGraph.ContainsEdge(x.Target, x.Source));

                    return PartialView("TopologicalFail", parallelEdges);
                }

                var dot = Visualizer.ToDotNotation(dependencyGraph);
                var orderedScripts = dependencyGraph.TopologicalSort();
                var script = new StringBuilder();

                if (model.WrapTransaction)
                {
                    script.AppendLine(XACT_ABORT);
                    script.AppendLine(BATCH_SEPERATOR);
                    script.AppendLine();
                    script.AppendLine(BEGIN_TRAN);
                    script.AppendLine();
                }
                
                if (model.DropsAtTop)
                {
                    foreach (var scriptFile in orderedScripts.Reverse())
                    {
                        foreach (var createObj in scriptFile.Creates.Where(x => !x.Ignore && !x.IsSystemObject && !x.IsDescendant))
                        {
                            script.Append(createObj.ScriptDropStatement());
                        }
                    }
                }

                foreach (var scriptFile in orderedScripts)
                {
                    script.AppendFormat("-- {1}{0}", Environment.NewLine, scriptFile.FileName);
                    script.AppendLine(scriptFile.Content);

                    if (model.WrapTransaction)
                    {
                        script.AppendLine("IF @@ERROR <> 0");
                        //script.AppendFormat("RAISERROR('! Error occurred when executing ''{0}''', 20, -1) WITH LOG{1}", scriptFile.FileName, Environment.NewLine);
                        script.AppendLine("SET NOEXEC ON");
                        script.AppendLine("GO");
                        script.AppendLine();
                    }
                }

                if (model.WrapTransaction)
                {
                    script.AppendLine(END_TRAN);
                    script.AppendLine("GO");
                    script.AppendLine();
                    script.AppendLine("IF @@ERROR <> 0");
                    script.AppendLine("SET NOEXEC ON");
                    script.AppendLine("GO");
                    script.AppendLine();
                    script.AppendLine("DECLARE @Success BIT = 1");
                    script.AppendLine();
                    script.AppendLine("SET NOEXEC OFF");
                    script.AppendLine();
                    script.AppendLine("IF @Success = 0 AND @@TRANCOUNT > 0");
                    script.AppendLine("ROLLBACK");
                    script.AppendLine("GO");
                }

                var output = script.ToString();
                if (model.NormaliseLineEndings)
                {
                    output = output.Replace(WINDOWS_LINE_ENDING, UNIX_LINE_ENDING).Replace(UNIX_LINE_ENDING, WINDOWS_LINE_ENDING);
                }

                var filteredScriptFiles = orderedScripts.Select(x =>
                {
                    x.Creates = x.FilteredCreates().GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                    x.DependsOn = x.UniqueFilteredDependsOn(model.CaseSensitive).GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                    return x;
                });

                return PartialView("Consolidated", new Consolidated { Script = output, DotNotation = dot, ScriptFiles = filteredScriptFiles });
            }

            return View();
        }
    }
}