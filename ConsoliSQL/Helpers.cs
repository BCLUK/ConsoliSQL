using ConsoliSQL.Models;
using Microsoft.SqlServer.TransactSql.ScriptDom;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Web;

namespace ConsoliSQL
{
    public static class Helpers
    {
        public static void FindDependencies(object obj, HashSet<SqlObject> sqlObjects, ScriptFile scriptFile, ref bool isDescendant)
        {
            GetDependency(obj, sqlObjects, scriptFile, ref isDescendant);
            
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
                            var isDescendantCopy = isDescendant;
                            FindDependencies(propVal, sqlObjects, scriptFile, ref isDescendantCopy);
                        }
                    }
                }
            }
        }
        
        public static void GetDependency(object obj, HashSet<SqlObject> sqlObjects, ScriptFile scriptFile, ref bool isDescendant)
        {
            if (obj is FunctionCall)
            {
                if (((FunctionCall)obj).CallTarget != null)
                {
                    sqlObjects.Add(new SqlObject(((FunctionCall)obj).FunctionName.Value, SqlObjectType.ScalarFunction, false, ((FunctionCall)obj).FunctionName.FirstTokenIndex, scriptFile, isDescendant));
                }
            }
            else if (obj is SchemaObjectFunctionTableReference)
            {
                sqlObjects.Add(new SqlObject(((SchemaObjectFunctionTableReference)obj).SchemaObject.BaseIdentifier.Value, SqlObjectType.TableValuedFunction | SqlObjectType.InlineTableValuedFunction, false, ((SchemaObjectFunctionTableReference)obj).SchemaObject.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is ExecutableProcedureReference)
            {
                sqlObjects.Add(new SqlObject(((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.Value, SqlObjectType.Procedure, false, ((ExecutableProcedureReference)obj).ProcedureReference.ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is NamedTableReference)
            {
                // Gets tables and views
                sqlObjects.Add(new SqlObject(((NamedTableReference)obj).SchemaObject.BaseIdentifier.Value, SqlObjectType.TableOrView, false, ((NamedTableReference)obj).SchemaObject.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is TriggerObject)
            {
                sqlObjects.Add(new SqlObject(((TriggerObject)obj).Name.BaseIdentifier.Value, SqlObjectType.Trigger, false, ((TriggerObject)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is DropTableStatement)
            {
                // You can drop multiple objects in one drop statement e.g.: DROP PROCEDURE USP4, USP5, USP6
                foreach (var table in ((DropTableStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(table.BaseIdentifier.Value, SqlObjectType.Table, false, table.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
                }
            }
            else if (obj is DropFunctionStatement)
            {
                foreach (var function in ((DropFunctionStatement)obj).Objects)
                {
                    // Needs reviewing                                                        v
                    sqlObjects.Add(new SqlObject(function.BaseIdentifier.Value, SqlObjectType.ScalarFunction, false, function.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlStatement)obj, isDescendant));
                }
            }
            else if (obj is DropIndexClause)
            {
                sqlObjects.Add(new SqlObject(((DropIndexClause)obj).Index.Value, SqlObjectType.Index, false, ((DropIndexClause)obj).Index.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
                sqlObjects.Add(new SqlObject(((DropIndexClause)obj).Object.BaseIdentifier.Value, SqlObjectType.Table, false, ((DropIndexClause)obj).Object.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
            }
            else if (obj is BackwardsCompatibleDropIndexClause)
            {
                sqlObjects.Add(new SqlObject(((BackwardsCompatibleDropIndexClause)obj).Index.ChildIdentifier.Value, SqlObjectType.Index, false, ((BackwardsCompatibleDropIndexClause)obj).Index.ChildIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
                sqlObjects.Add(new SqlObject(((BackwardsCompatibleDropIndexClause)obj).Index.BaseIdentifier.Value, SqlObjectType.Table, false, ((BackwardsCompatibleDropIndexClause)obj).Index.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
            }
            else if (obj is DropProcedureStatement)
            {
                foreach (var procedure in ((DropProcedureStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(procedure.BaseIdentifier.Value, SqlObjectType.Procedure, false, procedure.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
                }
            }
            else if (obj is DropTriggerStatement)
            {
                foreach (var trigger in ((DropTriggerStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(trigger.BaseIdentifier.Value, SqlObjectType.Trigger, false, trigger.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
                }
            }
            else if (obj is DropViewStatement)
            {
                foreach (var view in ((DropViewStatement)obj).Objects)
                {
                    sqlObjects.Add(new SqlObject(view.BaseIdentifier.Value, SqlObjectType.View, false, view.BaseIdentifier.FirstTokenIndex, scriptFile, null, true, (TSqlFragment)obj, isDescendant));
                }
            }
            else if (obj is AlterTableAddTableElementStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableAddTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableAlterColumnStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableAlterColumnStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableAlterIndexStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableAlterIndexStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
                sqlObjects.Add(new SqlObject(((AlterTableAlterIndexStatement)obj).IndexIdentifier.Value, SqlObjectType.Index, false, ((AlterTableAlterIndexStatement)obj).IndexIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableConstraintModificationStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableConstraintModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableDropTableElementStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableDropTableElementStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableRebuildStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableRebuildStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableSetStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableSetStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableSwitchStatement)
            {
                sqlObjects.Add(new SqlObject(((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableSwitchStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
                sqlObjects.Add(new SqlObject(((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableSwitchStatement)obj).TargetTable.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterTableTriggerModificationStatement)
            {
                var triggerTable = new SqlObject(((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, false, ((AlterTableTriggerModificationStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant);
                sqlObjects.Add(triggerTable);

                foreach (var trigger in ((AlterTableTriggerModificationStatement)obj).TriggerNames)
                {
                    sqlObjects.Add(new SqlObject(trigger.Value, SqlObjectType.Trigger, false, trigger.FirstTokenIndex, scriptFile, triggerTable, isDescendant));
                }
            }
            else if (obj is CreateFunctionStatement)
            {
                var returnType = ((CreateFunctionStatement)obj).ReturnType;
                sqlObjects.Add(new SqlObject(((CreateFunctionStatement)obj).Name.BaseIdentifier.Value, returnType is TableValuedFunctionReturnType ? SqlObjectType.TableValuedFunction : returnType is SelectFunctionReturnType ? SqlObjectType.InlineTableValuedFunction : SqlObjectType.ScalarFunction, true, ((CreateFunctionStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (obj is CreateProcedureStatement)
            {
                sqlObjects.Add(new SqlObject(((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.Value, SqlObjectType.Procedure, true, ((CreateProcedureStatement)obj).ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (obj is CreateViewStatement)
            {
                sqlObjects.Add(new SqlObject(((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.View, true, ((CreateViewStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (obj is CreateTriggerStatement)
            {
                var onTable = new SqlObject(((CreateTriggerStatement)obj).TriggerObject.Name.BaseIdentifier.Value, SqlObjectType.Table, false, ((CreateTriggerStatement)obj).TriggerObject.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant);
                sqlObjects.Add(onTable);
                sqlObjects.Add(new SqlObject(((CreateTriggerStatement)obj).Name.BaseIdentifier.Value, SqlObjectType.Trigger, true, ((CreateTriggerStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile, onTable, isDescendant)); // Added table as link object but not needed to drop trigger

                isDescendant = true;
            }
            else if (obj is CreateIndexStatement)
            {
                var onTable = new SqlObject(((CreateIndexStatement)obj).OnName.BaseIdentifier.Value, SqlObjectType.Table, false, ((CreateIndexStatement)obj).OnName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant);
                sqlObjects.Add(onTable);
                sqlObjects.Add(new SqlObject(((CreateIndexStatement)obj).Name.Value, SqlObjectType.Index, true, ((CreateIndexStatement)obj).Name.FirstTokenIndex, scriptFile, onTable, isDescendant));
            }
            else if (obj is CreateTableStatement)
            {
                sqlObjects.Add(new SqlObject(((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.Value, SqlObjectType.Table, true, ((CreateTableStatement)obj).SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is CreateTypeTableStatement)
            {
                sqlObjects.Add(new SqlObject(((CreateTypeTableStatement)obj).Name.BaseIdentifier.Value, SqlObjectType.TableValueParameter, true, ((CreateTypeTableStatement)obj).Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is CreateTypeUddtStatement)
            {
                // Represents the CREATE TYPE statement for user defined data types, the one that derive from Sql types.
            }
            else if (obj is CreateTypeUdtStatement)
            {
                // Represents the CREATE TYPE statement for user defined types, the one that derive from CLR types.
            }
            else if (obj is UserDataTypeReference)
            {
                var typedObj = (UserDataTypeReference)obj;
                sqlObjects.Add(new SqlObject(typedObj.Name.BaseIdentifier.Value, SqlObjectType.TableValueParameter, false, typedObj.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
            }
            else if (obj is AlterProcedureStatement)
            {
                var typedObj = (AlterProcedureStatement)obj;
                sqlObjects.Add(new SqlObject(typedObj.ProcedureReference.Name.BaseIdentifier.Value, SqlObjectType.Procedure, false, typedObj.ProcedureReference.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (obj is AlterFunctionStatement)
            {
                var typedObj = (AlterFunctionStatement)obj;
                sqlObjects.Add(new SqlObject(typedObj.Name.BaseIdentifier.Value, typedObj.ReturnType is TableValuedFunctionReturnType ? SqlObjectType.TableValuedFunction : typedObj.ReturnType is SelectFunctionReturnType ? SqlObjectType.InlineTableValuedFunction : SqlObjectType.ScalarFunction, false, typedObj.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (obj is AlterViewStatement)
            {
                var typedObj = (AlterViewStatement)obj;
                sqlObjects.Add(new SqlObject(typedObj.SchemaObjectName.BaseIdentifier.Value, SqlObjectType.View, false, typedObj.SchemaObjectName.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (obj is AlterTriggerStatement)
            {
                var typedObj = (AlterTriggerStatement)obj;
                sqlObjects.Add(new SqlObject(typedObj.TriggerObject.Name.BaseIdentifier.Value, SqlObjectType.Table, false, typedObj.TriggerObject.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));
                sqlObjects.Add(new SqlObject(typedObj.Name.BaseIdentifier.Value, SqlObjectType.Trigger, false, typedObj.Name.BaseIdentifier.FirstTokenIndex, scriptFile, isDescendant));

                isDescendant = true;
            }
            else if (!(obj is string) && obj is System.Collections.IEnumerable)
            {
                foreach (var item in (System.Collections.IEnumerable)obj)
                {
                    FindDependencies(item, sqlObjects, scriptFile, ref isDescendant);
                }
            }
        }
        
        public static string GetSqlObjectType(this SqlObjectType type)
        {
            // Used for scripting drops, so only used by create objects, which have correct type anyway
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
                case SqlObjectType.TableValueParameter: return "TT";

                default: return "";
            }
        }

        public static string GetSqlObjectKeyword(this SqlObjectType type)
        {
            // Used for scripting drops, so only used by create objects, which have correct type anyway
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
                //case SqlObjectType.TableValueParameter: return "TYPE";

                default: return "";
            }
        }

        public static string GetSqlObjectName(this SqlObjectType type)
        {
            switch (type)
            {
                case SqlObjectType.Table: return "Table";
                case SqlObjectType.View: return "View";
                case SqlObjectType.TableOrView: return "Table or View";
                case SqlObjectType.Index: return "Index";
                case SqlObjectType.ScalarFunction: return "Scalar Function";
                case SqlObjectType.TableValuedFunction:
                case SqlObjectType.InlineTableValuedFunction: return "Table Function";
                case SqlObjectType.Procedure: return "Procedure";
                case SqlObjectType.Trigger: return "Trigger";
                case SqlObjectType.TableValueParameter: return "Table Value Parameter";

                default: return "";
            }
        }

        public static string ScriptDropStatement(this SqlObject scriptObj)
        {
            var statement = new StringBuilder();

            switch (scriptObj.Type)
            {
                case SqlObjectType.Index:
                    statement.AppendFormat("IF INDEXPROPERTY(OBJECT_ID('{1}'), '{2}', 'IndexID') IS NOT NULL{0}", Environment.NewLine, scriptObj.LinkObject.Name, scriptObj.Name);
                    statement.AppendFormat("DROP INDEX {1} ON {2}{0}", Environment.NewLine, scriptObj.Name, scriptObj.LinkObject.Name);
                    statement.AppendFormat("GO{0}{0}", Environment.NewLine);
                    break;

                case SqlObjectType.TableValueParameter:
                    statement.AppendFormat("IF TYPE_ID('{1}') IS NOT NULL{0}", Environment.NewLine, scriptObj.Name);
                    statement.AppendFormat("DROP TYPE {1}{0}", Environment.NewLine, scriptObj.Name);
                    statement.AppendFormat("GO{0}{0}", Environment.NewLine);
                    break;

                default:
                    statement.AppendFormat("IF OBJECT_ID('{1}', '{2}') IS NOT NULL{0}", Environment.NewLine, scriptObj.Name, scriptObj.Type.GetSqlObjectType());
                    statement.AppendFormat("DROP {1} {2}{0}", Environment.NewLine, scriptObj.Type.GetSqlObjectKeyword(), scriptObj.Name);
                    statement.AppendFormat("GO{0}{0}", Environment.NewLine);
                    break;
            }

            return statement.ToString();
        }

        public static bool IsEqualTo(this SqlObjectType type1, SqlObjectType type2)
        {
            switch (type1)
            {
                case SqlObjectType.Table:
                case SqlObjectType.View:
                    return new[] { SqlObjectType.Table, SqlObjectType.View, SqlObjectType.TableOrView }.Contains(type2);

                default:
                    return type1.Equals(type2);
            }
        }
    }
}