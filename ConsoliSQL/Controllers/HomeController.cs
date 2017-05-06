using ConsoliSQL.Models;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using QuickGraph;
using QuickGraph.Algorithms;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
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
                                Helpers.FindDependencies(statement, dependsOn);
                            }
                        }

                        var sqlStatement = new StringBuilder();

                        for (int i = parseContent.FirstTokenIndex; i <= parseContent.LastTokenIndex; i++)
                        {
                            sqlStatement.Append(parseContent.ScriptTokenStream[i].Text);
                        }

                        sqlStatement.AppendLine();

                        if (model.AppendGo)
                        {
                            sqlStatement.AppendLine(BATCH_SEPERATOR);
                        }
                        
                        creates.RemoveWhere(x => x.StartsWith("#"));
                        dependsOn.RemoveWhere(x => x.StartsWith("#") || SqlSystemObjects.Instance.Objects.Contains(x));

                        scriptFiles.Add(new ScriptFile
                        {
                            FileName = file.FileName,
                            Content = sqlStatement.ToString(),
                            ObjectsCreated = creates,
                            DependsOnObjects = dependsOn,
                            ParseErrors = parseErrors.Select(x => $"{x.Message} Line: {x.Line}")
                        });
                    }
                }

                // This probably needs a check for case sensitivity.
                var dependencyMap = new Dictionary<string, ScriptFile>();
                foreach (var scriptFile in scriptFiles)
                {
                    foreach (var createObject in scriptFile.ObjectsCreated)
                    {
                        if (!dependencyMap.ContainsKey(createObject))
                        {
                            dependencyMap.Add(createObject, scriptFile);
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
                        if (dependencyMap.ContainsKey(dependancyObject) && !scriptFile.Equals(dependencyMap[dependancyObject]))
                        {
                            dependencyGraph.AddEdge(new SEdge<ScriptFile>(dependencyMap[dependancyObject], scriptFile));
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