using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class Home
    {
        [Required]
        public IEnumerable<HttpPostedFileBase> Files { get; set; }
    }
}