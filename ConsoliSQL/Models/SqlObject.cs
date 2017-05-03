using Microsoft.SqlServer.TransactSql.ScriptDom;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class SqlObject
    {
        public string Name { get; set; }
        public TSqlStatement Statement { get; set; }
        public ScriptFile SqlScript { get; set; }

        public override string ToString()
        {
            return SqlScript.FileName;
        }
    }
}