using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ConsoliSQL.Models
{
    public class GenerateResult
    {
        public const int GENERATE_CODE_SUCCESS = 0;
        public const int GENERATE_CODE_ERROR1 = 1;
        public const int GENERATE_CODE_ERROR2 = 2;

        public int ErrorCode { get; set; }
        public string Message { get; set; }
        public object State { get; set; }
    }
}