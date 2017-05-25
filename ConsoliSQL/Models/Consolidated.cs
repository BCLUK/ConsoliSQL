using QuickGraph;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class Consolidated
    {
        public string Script { get; set; }
        public string DotNotation { get; set; }
        public IEnumerable<ScriptFile> ScriptFiles { get; set; }
    }
}