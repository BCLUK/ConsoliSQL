using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class DropStatementException
    {
        public DropStatementException(int tokenLength, string statement)
        {
            TokenLength = tokenLength;
            Statement = statement;
        }
        
        public int TokenLength { get; set; }
        public string Statement { get; set; }
    }
}