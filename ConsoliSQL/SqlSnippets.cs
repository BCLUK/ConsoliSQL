using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Web;

namespace ConsoliSQL
{
    public sealed class SqlSnippets
    {
        private static SqlSnippets instance;

        private SqlSnippets()
        {
            var snippets = (IDictionary<string, object>)new ExpandoObject();
            
            foreach (var file in System.IO.Directory.GetFiles(HttpContext.Current.Server.MapPath("~\\SqlSnippets"), "*.sql"))
            {
                var filename = System.IO.Path.GetFileNameWithoutExtension(file);
                snippets.Add(filename, System.IO.File.ReadAllText(file));
            }

            Snippets = snippets;
        }

        public static SqlSnippets Instance
        {
            get
            {
                return instance ?? (instance = new SqlSnippets());
            }
        }
        
        public dynamic Snippets { get; set; }
    }
}