using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class Home
    {
        public IEnumerable<HttpPostedFileBase> Files { get; set; }
        public bool WrapTransaction { get; set; }
        public bool AppendGo { get; set; }
    }
}