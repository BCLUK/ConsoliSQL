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
        public static void FindDependencies(object obj, HashSet<string> list, List<int> tokens)
        {
            GetDependency(obj, list, tokens);

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
                            if (!GetDependency(propVal, list, tokens))
                            {
                                FindDependencies(propVal, list, tokens);
                            }
                        }
                    }
                }
            }
        }
        
        public static bool GetDependency(object obj, HashSet<string> list, List<int> tokens)
        {
            // Need to add creates aswell, should redo this whole part.
            if (obj.GetType() == typeof(FunctionCall))
            {
                if (((FunctionCall)obj).CallTarget != null)
                {
                    list.Add(((FunctionCall)obj).FunctionName.Value);
                    tokens.Add(((FunctionCall)obj).FunctionName.FirstTokenIndex);
                }

                return true;
            }
            else if (obj.GetType() == typeof(ExecutableProcedureReference))
            {
                list.Add(((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.Value);
                tokens.Add(((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(NamedTableReference))
            {
                list.Add(((NamedTableReference)obj).SchemaObject.BaseIdentifier.Value);
                tokens.Add(((NamedTableReference)obj).SchemaObject.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            //else if (obj.GetType() == typeof(CreateIndexStatement))
            //{
            //    list.Add(((CreateIndexStatement)obj).OnName.BaseIdentifier.Value);
            //    tokens.Add(((CreateIndexStatement)obj).OnName.BaseIdentifier.FirstTokenIndex);
            //    return true;
            //}
            else if (obj.GetType() == typeof(TriggerObject))
            {
                list.Add(((TriggerObject)obj).Name.BaseIdentifier.Value);
                tokens.Add(((TriggerObject)obj).Name.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(DropTableStatement))
            {
                // You can drop multiple objects in one drop statement e.g.: DROP PROCEDURE USP4, USP5, USP6
                foreach (var sqlObj in ((DropTableStatement)obj).Objects)
                {
                    list.Add(sqlObj.BaseIdentifier.Value);
                    tokens.Add(sqlObj.BaseIdentifier.FirstTokenIndex);
                }
                return true;
            }
            else if (obj.GetType() == typeof(DropFunctionStatement))
            {
                foreach (var sqlObj in ((DropFunctionStatement)obj).Objects)
                {
                    list.Add(sqlObj.BaseIdentifier.Value);
                    tokens.Add(sqlObj.BaseIdentifier.FirstTokenIndex);
                }
                return true;
            }
            else if (obj.GetType() == typeof(DropIndexStatement))
            {
                // TODO
                return true;
            }
            else if (obj.GetType() == typeof(DropProcedureStatement))
            {
                foreach (var sqlObj in ((DropProcedureStatement)obj).Objects)
                {
                    list.Add(sqlObj.BaseIdentifier.Value);
                    tokens.Add(sqlObj.BaseIdentifier.FirstTokenIndex);
                }
                return true;
            }
            else if (obj.GetType() == typeof(DropTriggerStatement))
            {
                foreach (var sqlObj in ((DropTriggerStatement)obj).Objects)
                {
                    list.Add(sqlObj.BaseIdentifier.Value);
                    tokens.Add(sqlObj.BaseIdentifier.FirstTokenIndex);
                }
                return true;
            }
            else if (obj.GetType() == typeof(DropViewStatement))
            {
                foreach (var sqlObj in ((DropViewStatement)obj).Objects)
                {
                    list.Add(sqlObj.BaseIdentifier.Value);
                    tokens.Add(sqlObj.BaseIdentifier.FirstTokenIndex);
                }
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableAddTableElementStatement))
            {
                list.Add(((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableAlterColumnStatement))
            {
                list.Add(((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableAlterIndexStatement))
            {
                list.Add(((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);

                list.Add(((AlterTableAlterIndexStatement)obj).IndexIdentifier.Value);
                tokens.Add(((AlterTableAlterIndexStatement)obj).IndexIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableConstraintModificationStatement))
            {
                list.Add(((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableDropTableElementStatement))
            {
                list.Add(((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableRebuildStatement))
            {
                list.Add(((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableSetStatement))
            {
                list.Add(((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableSwitchStatement))
            {
                list.Add(((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);

                list.Add(((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.Value);
                tokens.Add(((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(AlterTableTriggerModificationStatement))
            {
                list.Add(((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);

                foreach (var trigger in ((AlterTableTriggerModificationStatement)obj).TriggerNames)
                {
                    list.Add(trigger.Value);
                    tokens.Add(trigger.FirstTokenIndex);
                }
                
                return true;
            }
            if (obj.GetType() == typeof(CreateFunctionStatement))
            {
                list.Add(((CreateFunctionStatement)obj).Name.BaseIdentifier.Value);
                tokens.Add(((CreateFunctionStatement)obj).Name.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(CreateProcedureStatement))
            {
                list.Add(((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.Value);
                tokens.Add(((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(CreateViewStatement))
            {
                list.Add(((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(CreateTriggerStatement))
            {
                list.Add(((CreateTriggerStatement)obj).Name.BaseIdentifier.Value);
                tokens.Add(((CreateTriggerStatement)obj).Name.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(CreateIndexStatement))
            {
                list.Add(((CreateIndexStatement)obj).Name.Value);
                tokens.Add(((CreateIndexStatement)obj).Name.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() == typeof(CreateTableStatement))
            {
                list.Add(((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.Value);
                tokens.Add(((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex);
                return true;
            }
            else if (obj.GetType() != typeof(string) && obj.GetType().GetInterfaces().Contains(typeof(System.Collections.IEnumerable)))
            {
                foreach (var item in (System.Collections.IEnumerable)obj)
                {
                    FindDependencies(item, list, tokens);
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
                foreach (var item in (System.Collections.IEnumerable)obj)
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