namespace ConsoliSQL.Models
{
    public enum SqlObjectType
    {
        Table,
        View,
        TableOrView,

        Index,
        ScalarFunction,

        TableFunction,
        TableValuedFunction,
        InlineTableValuedFunction,

        Procedure,
        Trigger,
        TableValueParameter,

        Column
    }
}