using Microsoft.SqlServer.TransactSql.ScriptDom;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Web;

namespace ConsoliSQL
{
    public static class Helpers
    {
        public static void FindDependencies(object obj, HashSet<string> list)
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

        public static bool GetDependency(object obj, HashSet<string> list)
        {
            if (obj.GetType() == typeof(FunctionCall))
            {
                if (((FunctionCall)obj).CallTarget != null)
                    list.Add(((FunctionCall)obj).FunctionName.Value);

                return true;
            }
            else if (obj.GetType() == typeof(ExecutableProcedureReference))
            {
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

        public static void FindCreateStatements(object obj, HashSet<string> list)
        {
            GetCreateStatement(obj, list);

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
                            if (!GetCreateStatement(propVal, list))
                            {
                                FindCreateStatements(propVal, list);
                            }
                        }
                    }
                }
            }
        }

        public static bool GetCreateStatement(object obj, HashSet<string> list)
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
                    FindCreateStatements(item, list);
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