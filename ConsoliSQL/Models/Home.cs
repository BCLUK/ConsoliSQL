using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class Home
    {
        public IEnumerable<HttpPostedFileBase> Files { get; set; }
        public bool ErrorChecking { get; set; }
        public bool NormaliseLineEndings { get; set; }
        public bool CaseSensitive { get; set; }
        public bool PrependDrops { get; set; }
        public bool DropsAtTop { get; set; }
        public bool AllowCircularDependies { get; set; }
        public bool ColumnDependencies { get; set; }
        public bool AddProgressMarkers { get; set; } = true;
    }
}