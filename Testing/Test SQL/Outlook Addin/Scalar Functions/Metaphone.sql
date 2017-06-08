CREATE FUNCTION dbo.Metaphone(@str as varchar(70))
RETURNS varchar (25)
	/*
	Metaphone Algorithm
	
	Created by Lawrence Philips. 
	Metaphone presented in article in "Computer Language" December 1990 issue.
	Translated into t-SQL by Keith Henry (keithh_AT_lbm-solutions.com)
	
	             *********** BEGIN METAPHONE RULES ***********
	 Lawrence Philips' RULES follow:
	 The 16 consonant sounds:
	                                             |--- ZERO represents "th"
	                                             |
	      B  X  S  K  J  T  F  H  L  M  N  P  R  0  W  Y
	 Drop vowels
	
	 Exceptions:
	   Beginning of word: "ae-", "gn", "kn-", "pn-", "wr-"   ----> drop first letter
	   Beginning of word: "x"                                ----> change to "s"
	   Beginning of word: "wh-"                              ----> change to "w"
	   Beginning of word: vowel                              ----> Keep it
	
	
	Transformations:
	   B ----> B      unless at the end of word after "m", as in "dumb", "McComb"
	
	   C ----> X      (sh) if "-cia-" or "-ch-"
	           S      if "-ci-", "-ce-", or "-cy-"
	                  SILENT if "-sci-", "-sce-", or "-scy-"
	           K      otherwise, including in "-sch-"
	
	   D ----> J      if in "-dge-", "-dgy-", or "-dgi-"
	           T      otherwise
	
	   F ----> F
	
	   G ---->        SILENT if in "-gh-" and not at end or before a vowel
	                            in "-gn" or "-gned"
	                            in "-dge-" etc., as in above rule
	           J      if before "i", or "e", or "y" if not double "gg"
	           K      otherwise
	
	   H ---->        SILENT if after vowel and no vowel follows
	                         or after "-ch-", "-sh-", "-ph-", "-th-", "-gh-"
	           H      otherwise
	
	   J ----> J
	
	   K ---->        SILENT if after "c"
	           K      otherwise
	
	   L ----> L
	
	   M ----> M
	
	   N ----> N
	
	   P ----> F      if before "h"
	           P      otherwise
	
	   Q ----> K
	
	   R ----> R
	
	   S ----> X      (sh) if before "h" or in "-sio-" or "-sia-"
	           S      otherwise
	
	   T ----> X      (sh) if "-tia-" or "-tio-"
	           0      (th) if before "h"
	                  silent if in "-tch-"
	           T      otherwise
	
	   V ----> F
	
	   W ---->        SILENT if not followed by a vowel
	           W      if followed by a vowel
	
	   X ----> KS
	
	   Y ---->        SILENT if not followed by a vowel
	           Y      if followed by a vowel
	
	   Z ----> S
	*/


AS
BEGIN
Declare	@Result varchar(25),
	@str3	char(3),
	@str2 	char(2),
	@str1 	char(1),
	@strp 	char(1),
	@strLen tinyint,
	@cnt 	tinyint

set 	@strLen = 	len(@str)
set	@cnt	=	1
set	@Result	=	''

--Process beginning exceptions
set 	@str2 	= 	left(@str,2)
if 	@str2 	in 	('ae', 'gn', 'kn', 'pn', 'wr')
	begin
		set 	@str 	= 	right(@str , @strLen - 1)
		set 	@strLen = 	@strLen - 1
	end
if	@str2 	= 	'wh'	
	begin
		set 	@str 	= 	'w' + right(@str , @strLen - 2)
		set 	@strLen = 	@strLen - 1
	end
set 	@str1 	= 	left(@str,1)
if 	@str1	= 	'x' 	
	begin
		set 	@str 	= 	's' + right(@str , @strLen - 1)
	end
if 	@str1	in 	('a','e','i','o','u')
	begin
		set 	@str 	= 	right(@str , @strLen - 1)
		set 	@strLen = 	@strLen - 1
		set	@Result	=	@str1
	end

while @cnt <= @strLen
	begin
		set 	@str1 	= 	substring(@str,@cnt,1)
		if 	@cnt 	<> 	1	
			set	@strp	=	substring(@str,(@cnt-1),1)
		else	set	@strp	=	' '
	
	if @strp	<> 	@str1
		begin
			set 	@str2 	= 	substring(@str,@cnt,2)
				
			if  	@str1	in	('f','j','l','m','n','r')	
				set	@Result	=	@Result + @str1
	
			if  	@str1	=	'q'	set @Result	=	@Result + 'k'
			if  	@str1	=	'v'	set @Result	=	@Result + 'f'
			if  	@str1	=	'x'	set @Result	=	@Result + 'ks'
			if  	@str1	=	'z'	set @Result	=	@Result + 's'
	
			if 	@str1	=	'b'
				if @cnt = @strLen
					if 	substring(@str,(@cnt - 1),1) <> 'm'
						set	@Result	=	@Result + 'b'
				else
					set	@Result	=	@Result + 'b'
	
			if 	@str1	=	'c'

				if 	@str2 	= 	'ch' 	or 	substring(@str,@cnt,3) 	= 	'cia'
					set	@Result	=	@Result + 'x'
				else
					if 	@str2	in	('ci','ce','cy')	and	@strp	<>	's'
						set	@Result	=	@Result + 's'
					else	set	@Result	=	@Result + 'k'
	
			if 	@str1	=	'd'
				if 	substring(@str,@cnt,3) 	in  	('dge','dgy','dgi')
					set	@Result	=	@Result + 'j'
				else	set	@Result	=	@Result + 't'
	
			if 	@str1	=	'g'
				if 	substring(@str,(@cnt - 1),3) not in ('dge','dgy','dgi','dha','dhe','dhi','dho','dhu')
					if  @str2 in ('gi', 'ge','gy')
						set	@Result	=	@Result + 'j'
					else
						if	(@str2	<>	'gn') or ((@str2	<> 'gh') and ((@cnt + 1) <> @strLen))
							set	@Result	=	@Result + 'k'
	
			if  	@str1	=	'h'
				if 	(@strp not in ('a','e','i','o','u')) and (@str2 not in ('ha','he','hi','ho','hu'))
					if	@strp not in ('c','s','p','t','g')
						set	@Result	=	@Result + 'h'
	
			if  	@str1	=	'k'	
				if @strp <> 'c'
					set	@Result	=	@Result + 'k'
	
			if  	@str1	=	'p'	
				if @str2 = 'ph'
					set	@Result	=	@Result + 'f'
				else
					set	@Result	=	@Result + 'p'
	
			if 	@str1	=	's'
				if 	substring(@str,@cnt,3) 	in  	('sia','sio') or @str2 = 'sh'
					set	@Result	=	@Result + 'x'
				else	set	@Result	=	@Result + 's'
	
			if 	@str1	=	't'
				if 	substring(@str,@cnt,3) 	in  	('tia','tio')
					set	@Result	=	@Result + 'x'
				else	
					if	@str2	=	'th'
						set	@Result	=	@Result + '0'
					else
						if substring(@str,@cnt,3) <> 'tch'
							set	@Result	=	@Result + 't'
	
			if 	@str1	=	'w'
				if @str2 not in('wa','we','wi','wo','wu')
					set	@Result	=	@Result + 'w'
	
			if 	@str1	=	'y'
				if @str2 not in('ya','ye','yi','yo','yu')
					set	@Result	=	@Result + 'y'
		end
		set 	@cnt	=	@cnt + 1
	end
	RETURN @Result
END