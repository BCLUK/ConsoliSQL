-- test is printed
set xact_abort off
go

begin tran

declare @test decimal = 1 / 0

print 'test'

rollback




-- test is NOT printed
set xact_abort on
go

begin tran

declare @test decimal = 1 / 0

print 'test'

rollback