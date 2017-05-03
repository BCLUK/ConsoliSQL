using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace ConsoliSQL
{
    public sealed class SqlSystemObjects
    {
        private static SqlSystemObjects instance = null;

        private SqlSystemObjects()
        {
            Objects = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            using (var reader = File.OpenText(Path.Combine(HttpContext.Current.Server.MapPath("~"), "SqlSystemObjects.txt")))
            {
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    Objects.Add(line);
                }
            }
        }

        public static SqlSystemObjects Instance
        {
            get
            {
                return instance ?? new SqlSystemObjects();
            }
        }

        public HashSet<string> Objects { get; set; }
    }
}