using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class ScriptFile
    {
        public ScriptFile()
        {
            Uid = Guid.NewGuid().ToString();
        }

        public string Uid { get; set; }
        public string FileName { get; set; }
        public string Content { get; set; }
        public IEnumerable<string> CreateObjects { get; set; }
        public IEnumerable<string> DependsOn { get; set; }

        public override string ToString() => FileName;
    }
}