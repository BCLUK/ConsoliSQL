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
        }

        public string Name { get; set; }
        public SqlObjectType Type { get; set; }
        public bool IsCreate { get; set; }
        public int NameTokenIndex { get; set; }
        public ScriptFile File { get; set; }
        public bool Ignore { get; set; }
        public bool IsSystemObject { get; set; }

        private static bool IsTemporaryTable(string name) =>
            System.Text.RegularExpressions.Regex.IsMatch(name, "^##?");
    }

    public enum SqlObjectType
    {
        Table,
        View,
        Index,
        Function,
        Procedure,
        Trigger
    }
}