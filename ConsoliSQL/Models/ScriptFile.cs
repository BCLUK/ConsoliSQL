using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class ScriptFile
    {
        public int Order { get; set; }
        public string FileName { get; set; }
        public string Content { get; set; }
        public IEnumerable<SqlObject> Creates { get; set; }
        public IEnumerable<SqlObject> DependsOn { get; set; }
        public IEnumerable<string> ParseErrors { get; set; }
        public string Overview { get; set; }

        public override string ToString() => FileName;

        public IEnumerable<SqlObject> FilteredCreates() =>
            Creates.Where(x => !x.Ignore && !x.IsSystemObject && !x.IsDescendant);

        public IEnumerable<SqlObject> FilteredDependsOn() =>
            DependsOn.Where(x => !x.Ignore && !x.IsSystemObject);

        public IEnumerable<SqlObject> UniqueFilteredDependsOn(bool isCaseSensitive) =>
            FilteredDependsOn().GroupBy(y => y.Name, isCaseSensitive ? StringComparer.Ordinal : StringComparer.OrdinalIgnoreCase).Select(y => y.First());
    }
}