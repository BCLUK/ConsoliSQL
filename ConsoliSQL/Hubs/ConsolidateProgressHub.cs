using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.AspNet.SignalR;

namespace ConsoliSQL.Hubs
{
    public class ConsolidateProgressHub : Hub
    {
        public static void ReportProgress(string scriptFile, double percent)
        {
            var context = GlobalHost.ConnectionManager.GetHubContext<ConsolidateProgressHub>();
            context.Clients.All.reportProgress(scriptFile, Math.Round(percent, 2), percent);
        }
    }
}