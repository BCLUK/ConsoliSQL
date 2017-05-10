using ConsoliSQL.Models;
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
        public static void FindDependencies(object obj, HashSet<SqlObject> sqlObjects, ScriptFile scriptFile)
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
        
        public static void GetDependency(object obj, HashSet<SqlObject> sqlObjects, ScriptFile scriptFile)
        {
            var objType = obj.GetType();
            if (objType == typeof(FunctionCall))
            {
                if (((FunctionCall)obj).CallTarget != null)
                {
                    sqlObjects.Add(new SqlObject(((FunctionCall)obj).FunctionName.Value, SqlObjectType.ScalarFunction, false, ((FunctionCall)obj).FunctionName.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(SchemaObjectFunctionTableReference))
            {
                sqlObjects.Add(new SqlObject(((SchemaObjectFunctionTableReference)obj).SchemaObject.BaseIdentifier.Value, SqlObjectType.TableValuedFunction | SqlObjectType.InlineTableValuedFunction, false, ((SchemaObjectFunctionTableReference)obj).SchemaObject.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(ExecutableProcedureReference))
            {
                sqlObjects.Add(new SqlObject(((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.Value, SqlObjectType.Procedure, false, ((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(NamedTableReference))
            {
                sqlObjects.Add(new SqlObject(((NamedTableReference)obj).SchemaObject.BaseIdentifier.Value, SqlObjectType.Table, false, ((NamedTableReference)obj).SchemaObject.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(TriggerObject))
            {
                sqlObjects.Add(new SqlObject(((TriggerObject)obj).Name.BaseIdentifier.Value, SqlObjectType.Trigger, false, ((TriggerObject)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(DropTableStatement))
            {
                // You can drop multiple objects in one drop statement e.g.: DROP PROCEDURE USP4, USP5, USP6
                foreach (var table in ((DropTableStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(table.BaseIdentifier.Value, SqlObjectType.Table, false, table.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropFunctionStatement))
            {
                foreach (var function in ((DropFunctionStatement)obj).Objects)
                {
                    // Needs reviewing                                                        v
                    sqlObjects.Add(new SqlObject(function.BaseIdentifier.Value, SqlObjectType.ScalarFunction, false, function.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropIndexClause))
            {
                sqlObjects.Add(new SqlObject(((DropIndexClause)obj).Index.Value, SqlObjectType.Index, false, ((DropIndexClause)obj).Index.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new SqlObject(((DropIndexClause)obj).Object.BaseIdentifier.Value, SqlObjectType.Table, false, ((DropIndexClause)obj).Object.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(BackwardsCompatibleDropIndexClause))
            {
                sqlObjects.Add(new SqlObject(((BackwardsCompatibleDropIndexClause)obj).Index.ChildIdentifier.Value, SqlObjectType.Index, false, ((BackwardsCompatibleDropIndexClause)obj).Index.ChildIdentifier.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new SqlObject(((BackwardsCompatibleDropIndexClause)obj).Index.BaseIdentifier.Value, SqlObjectType.Table, false, ((BackwardsCompatibleDropIndexClause)obj).Index.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(DropProcedureStatement))
            {
                foreach (var procedure in ((DropProcedureStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(procedure.BaseIdentifier.Value, SqlObjectType.Procedure, false, procedure.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropTriggerStatement))
            {
                foreach (var trigger in ((DropTriggerStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(trigger.BaseIdentifier.Value, SqlObjectType.Trigger, false, trigger.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(DropViewStatement))
            {
                foreach (var view in ((DropViewStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(view.BaseIdentifier.Value, SqlObjectType.View, false, view.BaseIdentifier.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(AlterTableAddTableElementStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableAlterColumnStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableAlterIndexStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new SqlObject(((AlterTableAlterIndexStatement)obj).IndexIdentifier.Value, SqlObjectType.Index, false, ((AlterTableAlterIndexStatement)obj).IndexIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableConstraintModificationStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableDropTableElementStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableRebuildStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableSetStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableSwitchStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
                sqlObjects.Add(new SqlObject(((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(AlterTableTriggerModificationStatement))
            {
                sqlObjects.Add(new SqlObject(((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));

                foreach (var trigger in ((AlterTableTriggerModificationStatement)obj).TriggerNames)
                {
                    sqlObjects.Add(new SqlObject(trigger.Value, SqlObjectType.Trigger, false, trigger.FirstTokenIndex, scriptFile));
                }
            }
            else if (objType == typeof(CreateFunctionStatement))
            {
                var returnType = ((CreateFunctionStatement)obj).ReturnType;
                sqlObjects.Add(new SqlObject(((CreateFunctionStatement)obj).Name.BaseIdentifier.Value, returnType is TableValuedFunctionReturnType ? SqlObjectType.TableValuedFunction : returnType is SelectFunctionReturnType ? SqlObjectType.InlineTableValuedFunction : SqlObjectType.ScalarFunction, true, ((CreateFunctionStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateProcedureStatement))
            {
                sqlObjects.Add(new SqlObject(((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.Value, SqlObjectType.Procedure, true, ((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateViewStatement))
            {
                sqlObjects.Add(new SqlObject(((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.View, true, ((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateTriggerStatement))
            {
                sqlObjects.Add(new SqlObject(((CreateTriggerStatement)obj).Name.BaseIdentifier.Value, SqlObjectType.Trigger, true, ((CreateTriggerStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType == typeof(CreateIndexStatement))
            {
                var onTable = new SqlObject(((CreateIndexStatement)obj).OnName.BaseIdentifier.Value, SqlObjectType.Table, false, ((CreateIndexStatement)obj).OnName.BaseIdentifier.FirstTokenIndex, scriptFile);
                sqlObjects.Add(onTable);
                sqlObjects.Add(new SqlObject(((CreateIndexStatement)obj).Name.Value, SqlObjectType.Index, true, ((CreateIndexStatement)obj).Name.FirstTokenIndex, scriptFile, onTable));
            }
            else if (objType == typeof(CreateTableStatement))
            {
                sqlObjects.Add(new SqlObject(((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, true, ((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile));
            }
            else if (objType != typeof(string) && objType.GetInterfaces().Contains(typeof(System.Collections.IEnumerable)))
            {
                foreach (var item in (System.Collections.IEnumerable)obj)
                {
                    FindDependencies(item, sqlObjects, scriptFile);
                }
            }
        }
        
        public static string GetSqlObjectType(this SqlObjectType type)
        {
            switch (type)
            {
                case SqlObjectType.Table: return "U";
                case SqlObjectType.View: return "V";
                //case SqlObjectType.Index: return "I";
                case SqlObjectType.ScalarFunction: return "FN";
                case SqlObjectType.TableValuedFunction: return "TF";
                case SqlObjectType.InlineTableValuedFunction: return "IF";
                case SqlObjectType.Procedure: return "P";
                case SqlObjectType.Trigger: return "TR";

                default: return "";
            }
        }

        public static string GetSqlObjectKeyword(this SqlObjectType type)
        {
            switch (type)
            {
                case SqlObjectType.Table: return "TABLE";
                case SqlObjectType.View: return "VIEW";
                //case SqlObjectType.Index: return "I";
                case SqlObjectType.ScalarFunction:
                case SqlObjectType.TableValuedFunction:
                case SqlObjectType.InlineTableValuedFunction: return "FUNCTION";
                case SqlObjectType.Procedure: return "PROCEDURE";
                case SqlObjectType.Trigger: return "TRIGGER";

                default: return "";
            }
        }

        public static string GetSqlObjectName(this SqlObjectType type)
        {
            switch (type)
            {
                case SqlObjectType.Table: return "Table";
                case SqlObjectType.View: return "View";
                case SqlObjectType.Index: return "Index";
                case SqlObjectType.ScalarFunction: return "Scalar Function";
                case SqlObjectType.TableValuedFunction:
                case SqlObjectType.InlineTableValuedFunction: return "Table Function";
                case SqlObjectType.Procedure: return "Procedure";
                case SqlObjectType.Trigger: return "Trigger";

                default: return "";
            }
        }
    }
}