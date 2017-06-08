
if not exists(select column_id  from sys.columns where name = 'V_EMAIL' and object_id = Object_ID('VISITORS') ) begin
	ALTER TABLE VISITORS ADD V_EMAIL Varchar(100) 
end


