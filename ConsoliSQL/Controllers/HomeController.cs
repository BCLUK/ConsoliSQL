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
        // GET: Home
        public ActionResult Index()
        {
            var test = SqlSystemObjects.Instance.Objects;

            return View();
        }

        [HttpPost]
        public ActionResult Index(Home model)
        {
            if (ModelState.IsValid)
            {
                var scriptFiles = new HashSet<ScriptFile>();

                foreach (var file in model.Files)
                {
                    var createObjects = new List<string>();
                    var dependsOn = new List<string>();
                    var sqlStatement = new StringBuilder();

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
                                GetParents(statement, createObjects);
                                FindDependencies(statement, dependsOn);
                            }
                        }
                        
                        for (int i = parseContent.FirstTokenIndex; i <= parseContent.LastTokenIndex; i++)
                        {
                            sqlStatement.Append(parseContent.ScriptTokenStream[i].Text);
                        }
                    }

                    createObjects.RemoveAll(x => x.StartsWith("#"));
                    dependsOn.RemoveAll(x => SqlSystemObjects.Instance.Objects.Contains(x) || x.StartsWith("#"));
                    dependsOn = dependsOn.Distinct().ToList();

                    scriptFiles.Add(new ScriptFile { FileName = file.FileName, Content = sqlStatement.ToString(), CreateObjects = createObjects, DependsOn = dependsOn });
                }

                var dependencyGraph = new AdjacencyGraph<ScriptFile, SEdge<ScriptFile>>();

                var map = new Dictionary<string, ScriptFile>();

                foreach (var scriptFile in scriptFiles)
                {
                    foreach (var createObject in scriptFile.CreateObjects)
                    {
                        if (!map.ContainsKey(createObject))
                        {
                            map.Add(createObject, scriptFile);
                        }
                    }
                }
                
                foreach (var scriptFile in scriptFiles)
                {
                    dependencyGraph.AddVertex(scriptFile);
                }

                foreach (var scriptFile in scriptFiles)
                {
                    foreach (var dependsOn in scriptFile.DependsOn)
                    {
                        if (map.ContainsKey(dependsOn) && !scriptFile.Equals(map[dependsOn]))
                        {
                            dependencyGraph.AddEdge(new SEdge<ScriptFile>(map[dependsOn], scriptFile));
                        }
                    }
                }

                var dot = Visualizer.ToDotNotation(dependencyGraph);
                
                var orderedScripts = dependencyGraph.TopologicalSort();

                var script = new StringBuilder();

                foreach (var scriptt in orderedScripts)
                {
                    script.AppendLine(scriptt.Content);
                }

                var output = script.ToString();

                Console.WriteLine();

                return View("Parsed", new Parsed { Script = output, DotNotation = dot, ScriptFiles = scriptFiles });
            }

            return View();
        }
        
        public static void FindDependencies(object obj, List<string> list)
        {
            GetDependency(obj, list);

            foreach (PropertyInfo prop in obj.GetType().GetProperties())
            {
                if (prop.Name == "ScriptTokenStream")
                {
                    return;
                }

                if (prop.CanRead)
                {
                    if (prop.GetIndexParameters().Length == 0)
                    {
                        var propVal = prop.GetValue(obj);
                        if (propVal != null)
                        {
                            if (!GetDependency(propVal, list))
                            {
                                FindDependencies(propVal, list);
                            }
                        }
                    }
                }
            }
        }

        public static bool GetDependency(object obj, List<string> list)
        {
            if (obj.GetType() == typeof(FunctionCall))
            {
                if (((FunctionCall)obj).CallTarget != null)
                    list.Add(((FunctionCall)obj).FunctionName.Value);

                return true;
            }
            else if (obj.GetType() == typeof(ExecutableProcedureReference))
            {
                // Possibly add ignore for m$ sprocs
                list.Add(((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() == typeof(NamedTableReference))
            {
                list.Add(((NamedTableReference)obj).SchemaObject.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() == typeof(CreateIndexStatement))
            {
                list.Add(((CreateIndexStatement)obj).OnName.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() == typeof(TriggerObject))
            {
                list.Add(((TriggerObject)obj).Name.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() != typeof(string) && obj.GetType().GetInterfaces().Contains(typeof(System.Collections.IEnumerable)))
            {
                var coll = (System.Collections.IEnumerable)obj;

                foreach (var item in coll)
                {
                    FindDependencies(item, list);
                }

                return true;
            }
            else
            {
                return false;
            }
        }

        public static void GetParents(object obj, List<string> list)
        {
            GetDependency2(obj, list);

            foreach (PropertyInfo prop in obj.GetType().GetProperties())
            {
                if (prop.Name == "ScriptTokenStream")
                {
                    return;
                }

                if (prop.CanRead)
                {
                    if (prop.GetIndexParameters().Length == 0)
                    {
                        var propVal = prop.GetValue(obj);
                        if (propVal != null)
                        {
                            if (!GetDependency2(propVal, list))
                            {
                                GetParents(propVal, list);
                            }
                        }
                    }
                }
            }
        }

        public static bool GetDependency2(object obj, List<string> list)
        {
            if (obj.GetType() == typeof(CreateFunctionStatement))
            {
                list.Add(((CreateFunctionStatement)obj).Name.BaseIdentifier.Value);

                return true;
            }
            else if (obj.GetType() == typeof(CreateProcedureStatement))
            {
                list.Add(((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() == typeof(CreateViewStatement))
            {
                list.Add(((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() == typeof(CreateTriggerStatement))
            {
                list.Add(((CreateTriggerStatement)obj).Name.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() == typeof(CreateIndexStatement))
            {
                list.Add(((CreateIndexStatement)obj).Name.Value);
                return true;
            }
            else if (obj.GetType() == typeof(CreateTableStatement))
            {
                list.Add(((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                return true;
            }
            else if (obj.GetType() != typeof(string) && obj.GetType().GetInterfaces().Contains(typeof(System.Collections.IEnumerable)))
            {
                var coll = (System.Collections.IEnumerable)obj;

                foreach (var item in coll)
                {
                    GetParents(item, list);
                }

                return true;
            }
            else
            {
                return false;
            }
        }
    }
}