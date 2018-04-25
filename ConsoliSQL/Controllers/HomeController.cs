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
using System.Net;
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
            Log("visit.csv");
            return View();
        }
        
        const string BATCH_SEPERATOR = "GO";

        const string WINDOWS_LINE_ENDING = "\r\n";
        const string UNIX_LINE_ENDING = "\n";

        const string ERROR_MESSAGE_FILES = "No files have been selected.";

        const string LOG_DIR = "Logs";

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
                    string rawContent;

                    using (var reader = new StreamReader(file.InputStream))
                    using (var stringReader = new StringReader((rawContent = reader.ReadToEnd())))
                    {
                        var parser = new TSql140Parser(false);
                        IList<ParseError> parseErrors;
                        var parseContent = (TSqlScript)parser.Parse(stringReader, out parseErrors);

                        scriptFile.FileName = Path.GetFileName(file.FileName);
                        scriptFile.ParseErrors = parseErrors.Select(x => $"{x.Message} Line: {x.Line}");

                        if (parseErrors.Count < 1)
                        {
                            foreach (var batch in parseContent.Batches)
                            {
                                foreach (var statement in batch.Statements)
                                {
                                    var isDescendant = false;
                                    Helpers.FindDependencies(statement, sqlObjects, scriptFile, ref isDescendant);
                                }
                            }

                            // The reason we don't filter out ignored/system/descendant objects here is so we can mark them up in the document view
                            scriptFile.Creates = sqlObjects.Where(x => x.IsCreate);
                            scriptFile.DependsOn = sqlObjects.Where(x => !x.IsCreate);

                            var escapedFilename = Microsoft.SqlServer.Management.SqlParser.Parser.EscapeSequence.SingleQuotedEscapeSequence.Escape(scriptFile.FileName);
                            var sqlStatement = new StringBuilder();

                            if (model.PrependDrops && !model.DropsAtTop)
                            {
                                foreach (var createObj in scriptFile.Creates.Where(x => !x.Ignore && !x.IsSystemObject && !x.IsDescendant))
                                {
                                    sqlStatement.Append(createObj.ScriptDropStatement());
                                    sqlStatement.AppendLine();

                                    if (model.ErrorChecking)
                                    {
                                        sqlStatement.Append(SqlSnippets.Instance.Snippets.ErrorCheck);
                                    }
                                }
                            }

                            var indiciesToObjects = scriptFile.Creates.Union(scriptFile.DependsOn).GroupBy(x => x.NameTokenIndex).Select(x => x.First()).ToDictionary(x => x.NameTokenIndex, x => x);
                            for (var b = 0; b < parseContent.Batches.Count; b++)
                            {
                                sqlStatement.AppendFormat("/* File: {1}, Batch: {2} */ GO{0}", Environment.NewLine, escapedFilename.Substring(1, escapedFilename.Length - 2), b + 1);

                                var batch = parseContent.Batches[b];
                                var content = parseContent.ScriptTokenStream.GetBatchContentWithComments(parseContent.FirstTokenIndex, parseContent.LastTokenIndex, batch.FirstTokenIndex, batch.LastTokenIndex);

                                sqlStatement.AppendLine(content);
                                sqlStatement.AppendLine(BATCH_SEPERATOR);
                                sqlStatement.AppendLine();

                                if (model.ErrorChecking)
                                {
                                    sqlStatement.Append(SqlSnippets.Instance.Snippets.ErrorCheck);
                                }
                            }

                            for (var i = parseContent.FirstTokenIndex; i <= parseContent.LastTokenIndex; i++)
                            {
                                var token = parseContent.ScriptTokenStream[i];
                                if (token.Text != null)
                                {
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

                            scriptFile.Content = sqlStatement.ToString();
                        }
                        else
                        {
                            using (var stringReader2 = new StringReader(rawContent))
                            {
                                string line;
                                var lineCount = 0;
                                var errorLines = parseErrors.Select(x => x.Line);

                                while ((line = stringReader2.ReadLine()) != null)
                                {
                                    if (errorLines.Any(x => x == ++lineCount))
                                    {
                                        var span = html.CreateElement("mark");
                                        span.SetAttributeValue("style", "background-color: red;");
                                        span.InnerHtml = line;

                                        html.DocumentNode.AppendChild(span);
                                    }
                                    else
                                    {
                                        html.DocumentNode.AppendChild(html.CreateTextNode(line));
                                    }

                                    html.DocumentNode.AppendChild(html.CreateTextNode(Environment.NewLine));
                                }
                            }
                        }

                        scriptFile.Overview = html.DocumentNode.OuterHtml;

                        scriptFiles.Add(scriptFile);
                    }
                }

                var scriptFilesNoErrors = scriptFiles.Where(x => !x.ParseErrors.Any());

                var dependencyGraph = new AdjacencyGraph<ScriptFile, SEdge<ScriptFile>>();
                foreach (var scriptFile in scriptFiles)
                {
                    dependencyGraph.AddVertex(scriptFile);
                }

                foreach (var scriptFile in scriptFilesNoErrors)
                {
                    foreach (var depObj in scriptFile.FilteredDependsOn())
                    {
                        // Search all script files for create object that isn't ignored (temporary table), is the same type as @depObj, has the same name as @depObj & isn't a descendant object
                        var createObj = scriptFilesNoErrors.SelectMany(x => x.Creates.Where(y => y.IsCreate && !y.Ignore && y.Type.IsEqualTo(depObj.Type) 
                        
                        //&& y.Name.Equals(depObj.Name, model.CaseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase)
                        
                        &&
                        (
                            y.Type == SqlObjectType.Column ?
                                y.Name.Equals(depObj.Name, model.CaseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase)
                                && y.LinkObject.Name.Equals(depObj.LinkObject.Name, model.CaseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase)
                                :
                                y.Name.Equals(depObj.Name, model.CaseSensitive ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase)
                        )

                        && !y.IsDescendant
                        
                        )).FirstOrDefault();

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

                if (model.ErrorChecking)
                {
                    script.Append(SqlSnippets.Instance.Snippets.ErrorCheckPrefix);
                }
                
                if (model.DropsAtTop)
                {
                    foreach (var scriptFile in orderedScripts.Reverse())
                    {
                        foreach (var createObj in scriptFile.Creates.Where(x => !x.Ignore && !x.IsSystemObject && !x.IsDescendant))
                        {
                            script.Append(createObj.ScriptDropStatement());
                            script.AppendLine();

                            if (model.ErrorChecking)
                            {
                                script.Append(SqlSnippets.Instance.Snippets.ErrorCheck);
                            }
                        }
                    }
                }

                foreach (var scriptFile in orderedScripts)
                {
                    script.Append(scriptFile.Content);
                }

                if (model.ErrorChecking)
                {
                    script.Append(SqlSnippets.Instance.Snippets.ErrorCheckSuffix);
                }

                var output = script.ToString().TrimEnd();
                if (model.NormaliseLineEndings)
                {
                    output = output.Replace(WINDOWS_LINE_ENDING, UNIX_LINE_ENDING).Replace(UNIX_LINE_ENDING, WINDOWS_LINE_ENDING);
                }
                
                var filteredScriptFiles = orderedScripts.Select(x =>
                {
                    x.Creates = x.ParseErrors.Any() ? new SqlObject[0] : x.FilteredCreates().GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                    x.DependsOn = x.ParseErrors.Any() ? new SqlObject[0] : x.UniqueFilteredDependsOn(model.CaseSensitive).GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                    return x;
                });

                Log("consolidate.csv", ModelState.IsValid, model.ErrorChecking, model.NormaliseLineEndings, model.CaseSensitive, model.PrependDrops, model.DropsAtTop, model.AllowCircularDependies, filesCount);

                return PartialView("Consolidated", new Consolidated { Script = output, DotNotation = dot, ScriptFiles = filteredScriptFiles });
            }

            return View();
        }

        private void Log(string file, params object[] messages)
        {
            var workingDir = Path.Combine(Server.MapPath("~"), LOG_DIR);
            if (!Directory.Exists(workingDir))
            {
                Directory.CreateDirectory(workingDir);
            }

            var logPath = Path.Combine(workingDir, file);
            var messageParts = new List<object> { DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"), User.Identity.Name, Request.UserHostAddress };

            try
            {
                messageParts.Add(Dns.GetHostEntry(Request.UserHostAddress).HostName);
            }
            catch
            {
                messageParts.Add("");
            }

            System.IO.File.AppendAllLines(logPath, new[] { string.Join(",", messageParts.Concat(messages)) });
        }
    }
}