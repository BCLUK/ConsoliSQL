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
        public static void FindDependencies(object obj, HashSet<Models.SqlObject> sqlObjects, Models.ScriptFile scriptFile)
        {
            GetDependency(obj, sqlObjects, scriptFile);
            
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
                            FindDependencies(propVal, sqlObjects, scriptFile);
                        }
                    }
                }
            }
        }
        
        public static void GetDependency(object obj, HashSet<Models.SqlObject> sqlObjects, Models.ScriptFile scriptFile)
        {
            var objType = obj.GetType();
            if (objType == typeof(FunctionCall))
            {
                if (((FunctionCall)obj).CallTarget != null)
                {
                    sqlObjects.Add(new Models.SqlObject(((FunctionCall)obj).FunctionName.Value, Models.SqlObjectType.Function, false, ((FunctionCall)obj).FunctionName.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(ExecutableProcedureReference))
            {
                sqlObjects.Add(new Models.SqlObject(((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.Value, Models.SqlObjectType.Procedure, false, ((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(NamedTableReference))
            {
                sqlObjects.Add(new Models.SqlObject(((NamedTableReference)obj).SchemaObject.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((NamedTableReference)obj).SchemaObject.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(TriggerObject))
            {
                sqlObjects.Add(new Models.SqlObject(((TriggerObject)obj).Name.BaseIdentifier.Value, Models.SqlObjectType.Trigger, false, ((TriggerObject)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(DropTableStatement))
            {
                // You can drop multiple objects in one drop statement e.g.: DROP PROCEDURE USP4, USP5, USP6
                foreach (var table in ((DropTableStatement)obj).Objects)
                {
                    sqlObjects.Add(new Models.SqlObject(table.BaseIdentifier.Value, Models.SqlObjectType.Table, false, table.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropFunctionStatement))
            {
                foreach (var function in ((DropFunctionStatement)obj).Objects)
                {
                    sqlObjects.Add(new Models.SqlObject(function.BaseIdentifier.Value, Models.SqlObjectType.Function, false, function.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropIndexClause))
            {
                sqlObjects.Add(new Models.SqlObject(((DropIndexClause)obj).Index.Value, Models.SqlObjectType.Index, false, ((DropIndexClause)obj).Index.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new Models.SqlObject(((DropIndexClause)obj).Object.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((DropIndexClause)obj).Object.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(BackwardsCompatibleDropIndexClause))
            {
                sqlObjects.Add(new Models.SqlObject(((BackwardsCompatibleDropIndexClause)obj).Index.ChildIdentifier.Value, Models.SqlObjectType.Index, false, ((BackwardsCompatibleDropIndexClause)obj).Index.ChildIdentifier.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new Models.SqlObject(((BackwardsCompatibleDropIndexClause)obj).Index.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((BackwardsCompatibleDropIndexClause)obj).Index.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(DropProcedureStatement))
            {
                foreach (var procedure in ((DropProcedureStatement)obj).Objects)
                {
                    sqlObjects.Add(new Models.SqlObject(procedure.BaseIdentifier.Value, Models.SqlObjectType.Procedure, false, procedure.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropTriggerStatement))
            {
                foreach (var trigger in ((DropTriggerStatement)obj).Objects)
                {
                    sqlObjects.Add(new Models.SqlObject(trigger.BaseIdentifier.Value, Models.SqlObjectType.Trigger, false, trigger.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropViewStatement))
            {
                foreach (var view in ((DropViewStatement)obj).Objects)
                {
                    sqlObjects.Add(new Models.SqlObject(view.BaseIdentifier.Value, Models.SqlObjectType.View, false, view.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(AlterTableAddTableElementStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableAlterColumnStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableAlterIndexStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new Models.SqlObject(((AlterTableAlterIndexStatement)obj).IndexIdentifier.Value, Models.SqlObjectType.Index, false, ((AlterTableAlterIndexStatement)obj).IndexIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableConstraintModificationStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableDropTableElementStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableRebuildStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableSetStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableSwitchStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new Models.SqlObject(((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableTriggerModificationStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, false, ((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));

                foreach (var trigger in ((AlterTableTriggerModificationStatement)obj).TriggerNames)
                {
                    sqlObjects.Add(new Models.SqlObject(trigger.Value, Models.SqlObjectType.Trigger, false, trigger.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(CreateFunctionStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((CreateFunctionStatement)obj).Name.BaseIdentifier.Value, Models.SqlObjectType.Function, true, ((CreateFunctionStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateProcedureStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.Value, Models.SqlObjectType.Procedure, true, ((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateViewStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.View, true, ((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateTriggerStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((CreateTriggerStatement)obj).Name.BaseIdentifier.Value, Models.SqlObjectType.Trigger, true, ((CreateTriggerStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateIndexStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((CreateIndexStatement)obj).Name.Value, Models.SqlObjectType.Index, true, ((CreateIndexStatement)obj).Name.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateTableStatement))
            {
                sqlObjects.Add(new Models.SqlObject(((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.Value, Models.SqlObjectType.Table, true, ((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType != typeof(string) && objType.GetInterfaces().Contains(typeof(System.Collections.IEnumerable)))
            {
                foreach (var item in (System.Collections.IEnumerable)obj)
                {
                    FindDependencies(item, sqlObjects, scriptFile);
                }
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