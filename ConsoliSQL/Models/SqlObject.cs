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
        }

        public string Name { get; set; }
        public SqlObjectType Type { get; set; }
        public bool IsCreate { get; set; }
        public int NameTokenIndex { get; set; }
        public ScriptFile File { get; set; }
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