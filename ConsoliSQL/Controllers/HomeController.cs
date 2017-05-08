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
            if (model.Files.Count() == 1 && model.Files.First() == null)
            {
                ModelState.AddModelError("Files", ERROR_MESSAGE_FILES);
            }

            if (ModelState.IsValid)
            {
                var scriptFiles = new HashSet<ScriptFile>();

                foreach (var file in model.Files)
                {
                    var creates = new HashSet<string>(model.CaseSensitive ? StringComparer.Ordinal : StringComparer.OrdinalIgnoreCase);
                    var dependsOn = new HashSet<string>(model.CaseSensitive ? StringComparer.Ordinal : StringComparer.OrdinalIgnoreCase);
                    var tempTokens = new List<int>();
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
                                Helpers.FindCreateStatements(statement, creates);
                                Helpers.FindDependencies(statement, dependsOn, tempTokens);
                            }
                        }

                        var sqlStatement = new StringBuilder();
                        var tempSqlStatement = new StringBuilder();

                        for (int i = parseContent.FirstTokenIndex; i <= parseContent.LastTokenIndex; i++)
                        {
                            var token = parseContent.ScriptTokenStream[i];
                            if (token.Text != null)
                            {
                                sqlStatement.Append(token.Text);
                                
                                if (tempTokens.Contains(i))
                                {
                                    var span = html.CreateElement("mark");
                                    if (SqlSystemObjects.Instance.Objects.Contains(token.Text))
                                    {
                                        span.SetAttributeValue("style", "background-color: #E0E0E0;");
                                    }
                                    else if (Regex.IsMatch(token.Text, "^##?"))
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
                        
                        creates.RemoveWhere(x => x.StartsWith("#"));
                        dependsOn.RemoveWhere(x => x.StartsWith("#") || SqlSystemObjects.Instance.Objects.Contains(x));

                        scriptFiles.Add(new ScriptFile
                        {
                            FileName = file.FileName,
                            Content = sqlStatement.ToString(),
                            ObjectsCreated = creates,
                            DependsOnObjects = dependsOn,
                            ParseErrors = parseErrors.Select(x => $"{x.Message} Line: {x.Line}"),
                            Overview = html.DocumentNode.OuterHtml
                        });
                    }
                }
                                
                // Contains all objects that are 'CREATE'd and the script they are created in.
                var createsToScript = new Dictionary<string, ScriptFile>(model.CaseSensitive ? StringComparer.Ordinal : StringComparer.OrdinalIgnoreCase);
                foreach (var scriptFile in scriptFiles)
                {
                    foreach (var createObject in scriptFile.ObjectsCreated)
                    {
                        if (!createsToScript.ContainsKey(createObject))
                        {
                            createsToScript.Add(createObject, scriptFile);
                        }
                    }
                }

                var dependencyGraph = new AdjacencyGraph<ScriptFile, SEdge<ScriptFile>>();
                foreach (var scriptFile in scriptFiles)
                {
                    dependencyGraph.AddVertex(scriptFile);
                }

                foreach (var scriptFile in scriptFiles)
                {
                    foreach (var dependancyObject in scriptFile.DependsOnObjects)
                    {
                        if (createsToScript.ContainsKey(dependancyObject) && !scriptFile.Equals(createsToScript[dependancyObject]))
                        {
                            dependencyGraph.AddEdge(new SEdge<ScriptFile>(createsToScript[dependancyObject], scriptFile));
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
                
                return View("Consolidated", new Consolidated { Script = output, DotNotation = dot, ScriptFiles = scriptFiles });
            }

            return View();
        }
    }
}