using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class ScriptFile
    {
        public string FileName { get; set; }
        public string Content { get; set; }
        public IEnumerable<SqlObject> ObjectsCreated { get; set; }
        public IEnumerable<SqlObject> DependsOnObjects { get; set; }
        public IEnumerable<string> ParseErrors { get; set; }
        public string Overview { get; set; }

        public override string ToString() => FileName;
    }
}