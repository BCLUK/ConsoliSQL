using Microsoft.SqlServer.TransactSql.ScriptDom;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class SqlObject
    {
        public SqlObject(string name, SqlObjectType type, bool isCreate, int nameTokenIndex, ScriptFile file)
        {
            Name = name;
            Type = type;
            IsCreate = isCreate;
            NameTokenIndex = nameTokenIndex;
            File = file;
            Ignore = IsTemporaryTable(Name);
            IsSystemObject = SqlSystemObjects.Instance.Objects.Contains(Name); // Good idea to fetch system objects with their type and improve this check..
            IsDrop = false;
        }

        public SqlObject(string name, SqlObjectType type, bool isCreate, int nameTokenIndex, ScriptFile file, SqlObject linkObject) : this(name, type, isCreate, nameTokenIndex, file)
        {
            LinkObject = linkObject;
        }

        public SqlObject(string name, SqlObjectType type, bool isCreate, int nameTokenIndex, ScriptFile file, SqlObject linkObject, bool isDrop, TSqlStatement sqlStatement) : this(name, type, isCreate, nameTokenIndex, file, linkObject)
        {
            IsDrop = isDrop;
            SqlStatement = sqlStatement;
        }

        public string Name { get; set; }
        public SqlObjectType Type { get; set; }
        public bool IsCreate { get; set; }
        public int NameTokenIndex { get; set; }
        public ScriptFile File { get; set; }
        public bool Ignore { get; set; }
        public bool IsSystemObject { get; set; }
        public SqlObject LinkObject { get; set; }
        public bool IsDrop { get; set; }
        public TSqlStatement SqlStatement { get; set; }

        private static bool IsTemporaryTable(string name) =>
            System.Text.RegularExpressions.Regex.IsMatch(name, "^##?");
    }

    public enum SqlObjectType
    {
        Table,
        View,
        TableOrView,
        Index,
        //Function,
        ScalarFunction,
        TableValuedFunction,
        InlineTableValuedFunction,
        Procedure,
        Trigger,
        TableValueParameter
    }
}