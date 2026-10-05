using ConsoliSQL.Models;
using HtmlAgilityPack;
using Microsoft.AspNet.SignalR;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using Newtonsoft.Json;
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
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace ConsoliSQL.Controllers
{
    [AllowCORSAttribute]
    [System.Web.Mvc.Authorize]
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
        const string OLDMAC_LINE_ENDING = "\r";

        const string ERROR_MESSAGE_FILES = "No files have been selected.";

        const string LOG_DIR = "Logs";

        private readonly object _lock = new object();
        private static readonly object _logLock = new object();

        [HttpPost]
        public ActionResult Index(Home model)
        {
            var res = GenerateTheScript(model);
            if (res.ErrorCode == GenerateResult.GENERATE_CODE_SUCCESS)
            {
                return PartialView("Consolidated", res.State);
            }
            else if (res.ErrorCode == GenerateResult.GENERATE_CODE_ERROR1)
            {
                ModelState.AddModelError("Files", ERROR_MESSAGE_FILES);
            }
            else if (res.ErrorCode == GenerateResult.GENERATE_CODE_ERROR2)
            {
                return PartialView("TopologicalFail", res.State);
            }

            return View();
        }

        private void ParseFile(string rawContent, IEnumerable<string> warnings, HashSet<ScriptFile> scriptFiles, string filename, ref int count, int filesCount, int order, bool columnDependencies, bool prependDrops, bool dropsAtTop, bool errorChecking, bool addProgressMarkers)
        {
            lock (_lock)
                Hubs.ConsolidateProgressHub.ReportProgress(User.Identity.Name, "Parsing<br>" + Path.GetFileName(filename), (double)++count / filesCount * 100);

            using (var stringReader = new StringReader(rawContent))
            {
                var sqlObjects = new HashSet<SqlObject>();
                var scriptFile = new ScriptFile { Order = order, Warnings = warnings };
                var html = new HtmlDocument();

                var parser = new TSql140Parser(false);
                IList<ParseError> parseErrors;
                var parseContent = (TSqlScript)parser.Parse(stringReader, out parseErrors);

                scriptFile.FileName = Path.GetFileName(filename);
                scriptFile.ParseErrors = parseErrors.Select(x => $"{x.Message} Line: {x.Line}");

                if (parseErrors.Count < 1)
                {
                    foreach (var batch in parseContent.Batches)
                    {
                        foreach (var statement in batch.Statements)
                        {
                            var isDescendant = false;
                            Helpers.FindDependencies(statement, sqlObjects, scriptFile, ref isDescendant, null, columnDependencies);
                        }
                    }

                    // The reason we don't filter out ignored/system/descendant objects here is so we can mark them up in the document view
                    scriptFile.Creates = sqlObjects.Where(x => x.IsCreate);
                    scriptFile.DependsOn = sqlObjects.Where(x => !x.IsCreate);

                    var escapedFilename = Microsoft.SqlServer.Management.SqlParser.Parser.EscapeSequence.SingleQuotedEscapeSequence.Escape(scriptFile.FileName);
                    var escapedFilenameInner = escapedFilename.Substring(1, escapedFilename.Length - 2);
                    var sqlStatement = new StringBuilder();

                    var lastErrorCheckInsertPos = -1;

                    if (prependDrops && !dropsAtTop)
                    {
                        foreach (var createObj in scriptFile.Creates.Where(x => !x.Ignore && !x.IsSystemObject && !x.IsDescendant))
                        {
                            sqlStatement.Append(createObj.ScriptDropStatement());
                            sqlStatement.AppendLine();

                            if (errorChecking)
                            {
                                lastErrorCheckInsertPos = sqlStatement.Length;
                                sqlStatement.Append(SqlSnippets.Instance.Snippets.ErrorCheck);
                            }
                        }
                    }

                    var indiciesToObjects = scriptFile.Creates.Union(scriptFile.DependsOn).GroupBy(x => x.NameTokenIndex).Select(x => x.First()).ToDictionary(x => x.NameTokenIndex, x => x);
                    for (var b = 0; b < parseContent.Batches.Count; b++)
                    {
                        sqlStatement.AppendFormat("/* File: {1}, Batch: {2} */ GO{0}", Environment.NewLine, escapedFilenameInner, b + 1);

                        var batch = parseContent.Batches[b];
                        var content = parseContent.ScriptTokenStream.GetBatchContentWithComments(parseContent.FirstTokenIndex, parseContent.LastTokenIndex, batch.FirstTokenIndex, batch.LastTokenIndex);

                        sqlStatement.AppendLine(content);
                        sqlStatement.AppendLine(BATCH_SEPERATOR);
                        sqlStatement.AppendLine();

                        if (errorChecking)
                        {
                            lastErrorCheckInsertPos = sqlStatement.Length;
                            sqlStatement.Append(SqlSnippets.Instance.Snippets.ErrorCheck);
                        }
                    }

                    if (addProgressMarkers && lastErrorCheckInsertPos >= 0)
                    {
                        sqlStatement.Insert(lastErrorCheckInsertPos, "/*__PROG__*/" + Environment.NewLine);
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

                lock (scriptFiles)
                    scriptFiles.Add(scriptFile);
            }
        }

        // Returns the script file that creates @depObj, or null if there isn't one or it's @scriptFile itself
        private ScriptFile FindLink(IEnumerable<ScriptFile> scriptFilesNoErrors, ScriptFile scriptFile, SqlObject depObj, bool columnDependencies, bool caseSensitive)
        {
            var createObj = Helpers.GetCreateObject(columnDependencies, caseSensitive, scriptFilesNoErrors, depObj);

            return createObj != null && !createObj.File.Equals(scriptFile) ? createObj.File : null;
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

            // Static because each request gets its own controller, and concurrent appends to the same file fail
            lock (_logLock)
            {
                System.IO.File.AppendAllLines(logPath, new[] { string.Join(",", messageParts.Concat(messages)) });
            }
        }

        private GenerateResult GenerateTheScript(Home model, bool scriptOnly = false)
        {
            if (model.Files == null || (model.Files.Count() == 1 && model.Files.First() == null))
            {
                return new GenerateResult { ErrorCode = GenerateResult.GENERATE_CODE_ERROR1, Message = ERROR_MESSAGE_FILES };
            }

            var scriptFiles = new HashSet<ScriptFile>();
            var count = 0;
            var filesCount = model.Files.Count();
            var tasks = new List<Task>();
            var order = 0;

            // Initialise singletons while in http context
            var temp = SqlSystemObjects.Instance;
            var temp2 = SqlSnippets.Instance;

            foreach (var file in model.Files)
            {
                using (var memoryStream = new MemoryStream())
                {
                    file.InputStream.CopyTo(memoryStream);
                    var rawContent = Helpers.DecodeScript(memoryStream.ToArray());
                    var encodingWarning = Helpers.GetReplacementCharacterWarning(rawContent);
                    var fileWarnings = encodingWarning == null ? new string[0] : new[] { encodingWarning };
                    // Taken here rather than inside the task, otherwise the order depends on which task runs first
                    var fileOrder = ++order;
                    tasks.Add(Task.Run(() => ParseFile(rawContent, fileWarnings, scriptFiles, file.FileName, ref count, filesCount, fileOrder, model.ColumnDependencies, model.PrependDrops, model.DropsAtTop, model.ErrorChecking, model.AddProgressMarkers)));
                }
            }

            Task.WhenAll(tasks.ToArray()).Wait();

            // Doing this allows the scripts to stay in the order they came in,
            // making the order of files that don't have any dependencies more predictable.
            scriptFiles = new HashSet<ScriptFile>(scriptFiles.OrderBy(x => x.Order));

            Hubs.ConsolidateProgressHub.ReportProgress(User.Identity.Name, "Linking scripts", 100);

            var scriptFilesNoErrors = scriptFiles.Where(x => !x.ParseErrors.Any());

            var dependencyGraph = new AdjacencyGraph<ScriptFile, SEdge<ScriptFile>>();
            foreach (var scriptFile in scriptFiles)
            {
                dependencyGraph.AddVertex(scriptFile);
            }

            var scriptFilesCount = scriptFilesNoErrors.Count();

            tasks.Clear();

            var links = scriptFilesNoErrors.SelectMany(x => x.FilteredDependsOn().Select(y => new { ScriptFile = x, DepObj = y })).ToList();
            var linkSources = new ScriptFile[links.Count];

            for (var i = 0; i < links.Count; i++)
            {
                var index = i;
                tasks.Add(Task.Run(() => linkSources[index] = FindLink(scriptFilesNoErrors, links[index].ScriptFile, links[index].DepObj, model.ColumnDependencies, model.CaseSensitive)));
            }

            Task.WhenAll(tasks).Wait();

            // Edges are added in a fixed order because the topological sort follows them in the order they were added
            for (var i = 0; i < links.Count; i++)
            {
                if (linkSources[i] != null && !dependencyGraph.ContainsEdge(linkSources[i], links[i].ScriptFile))
                {
                    dependencyGraph.AddEdge(new SEdge<ScriptFile>(linkSources[i], links[i].ScriptFile));
                }
            }

            Hubs.ConsolidateProgressHub.ReportProgress(User.Identity.Name, "Scripts linked<br>Please wait", 100);

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

                return new GenerateResult { ErrorCode = GenerateResult.GENERATE_CODE_ERROR2, Message = "Topological fail", State = parallelEdges };
            }

            var dot = scriptFilesCount <= 100 ? Visualizer.ToDotNotation(dependencyGraph) : "graph G { 0 [label=\"Graph will only display if there are l00 or less scripts!\"]; }";
            var orderedScripts = dependencyGraph.TopologicalSort().ToList();
            var script = new StringBuilder();

            if (model.ErrorChecking)
            {
                script.Append(SqlSnippets.Instance.Snippets.ErrorCheckPrefix);
            }

            if (model.DropsAtTop)
            {
                foreach (var scriptFile in orderedScripts.AsEnumerable().Reverse())
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

            var progressRegex = new Regex(@"/\*__PROG__\*/\r?\n?");
            var scriptText = script.ToString();
            var totalProgress = progressRegex.Matches(scriptText).Count;
            var progressIndex = 0;
            var padding = new string(' ', 100);
            var output = progressRegex.Replace(scriptText, m =>
            {
                progressIndex++;
                var pct = totalProgress == 0 ? 100m : Math.Round(100m * progressIndex / totalProgress, 2);
                return $"PRINT '{padding}[{pct}%] ({progressIndex}/{totalProgress})'{Environment.NewLine}";
            }).TrimEnd();
            if (model.NormaliseLineEndings)
            {
                output = output.Replace(WINDOWS_LINE_ENDING, UNIX_LINE_ENDING).Replace(OLDMAC_LINE_ENDING, UNIX_LINE_ENDING).Replace(UNIX_LINE_ENDING, WINDOWS_LINE_ENDING);
            }

            var filteredScriptFiles = orderedScripts.Select(x =>
            {
                x.Creates = x.ParseErrors.Any() ? new SqlObject[0] : x.FilteredCreates().GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                x.DependsOn = x.ParseErrors.Any() ? new SqlObject[0] : x.UniqueFilteredDependsOn(model.CaseSensitive).GroupBy(y => y.Type).Select(y => y.OrderBy(z => z.Name)).SelectMany(y => y);
                return x;
            });

            Log("consolidate.csv", ModelState.IsValid, model.ErrorChecking, model.NormaliseLineEndings, model.CaseSensitive, model.PrependDrops, model.DropsAtTop, model.AllowCircularDependies, model.AddProgressMarkers, filesCount);

            Hubs.ConsolidateProgressHub.ReportProgress(User.Identity.Name, "Done", 100);

            //return PartialView("Consolidated", new Consolidated { Script = output, DotNotation = dot, ScriptFiles = filteredScriptFiles });
            var warnings = orderedScripts.SelectMany(x => x.Warnings.Select(y => $"{x.FileName}: {y}")).ToList();

            return new GenerateResult { ErrorCode = GenerateResult.GENERATE_CODE_SUCCESS, Message = "Success", Warnings = warnings, State = scriptOnly ? (object)output : new Consolidated { Script = output, DotNotation = dot, ScriptFiles = filteredScriptFiles } };
        }

        [HttpPost]
        [AllowAnonymous]
        public ActionResult GenerateScript(Home model)
        {
            return Content(JsonConvert.SerializeObject(GenerateTheScript(model, true)), "application/json");
        }
    }
}