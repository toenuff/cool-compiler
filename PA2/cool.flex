/*
%%
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <math.h>
/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

%x str
%x comment
%x line_comment
/*
 * Define names for regular expressions here.
 */
DARROW          =>
ASSIGNMENT      <-

CLASS_REG       [c|C][l|L][a|A][s|S][s|S]
ELSE_REG        [e|E][l|L][s|S][e|E]
FI_REG          [f|F][i|I]
IF_REG          [i|I][f|F]
IN_REG          [i|I][n|N]
INHERITS_REG    [i|I][n|N][h|H][e|E][r|R][i|I][t|T][s|S]
LET_REG         [l|L][e|E][t|T]
LOOP_REG        [l|L][o|O][o|O][p|P]
POOL_REG        [p|P][o|O][o|O][l|L]
THEN_REG        [t|T][h|H][e|E][n|N]
WHILE_REG       [w|W][h|H][i|I][l|L][e|E]
CASE_REG        [c|C][a|A][s|S][e|E]
ESAC_REG        [e|E][s|S][a|A][c|C]
OF_REG          [o|O][f|F]
NEW_REG         [n|N][e|E][w|W]
ISVOID_REG      [i|I][s|S][v|V][o|O][i|I][d|D]
TRUE_REG        t[r|R][u|U][e|E]
FALSE_REG       f[a|A][l|L][s|S][e|E]
NOT_REG         [n|N][o|O][t|T]

DIGIT           [0-9]+

TYPE_ID         [A-Z][a-zA-Z0-9_]+
OBJECT_ID       [a-z][a-zA-Z0-9_]+

PLUS_OP         "+"
MINUS_OP        "-"
MULT_OP         "*"
DIV_OP          "/"

OPEN_PARA       [\(]
CLOSE_PARA      [\)]
OPEN_CURLY      [\{]
CLOSE_CURLY     [\}]
OPEN_BRACKET    [\[]
CLOSE_BRACKET   [\]]

SEMICOLON       [;]+
METHOD_ACCESS   "."
LESS            [<]+
GREATER         [>]+
COLON           [:]+

WHITE_SPACE     [ \t\f\r\v]+
NEW_LINE        [\n]
NULL_CHAR       [\0]
%%
 /*
  *  Nested comments
  */

"--"                    BEGIN(line_comment);
<line_comment>[^\n]*    /* eat up anything thats not a newline */
<line_comment>\n        { curr_lineno++;
                          BEGIN(INITIAL);
                        }


  
"(*"                    BEGIN(comment);
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"(*"           /* eat up new open comment */
<comment>"*"+[^*)\n]*   /* eat up '*'s not followed by ')'s */
<comment>\n             curr_lineno++;    
<comment>"*"+")"        BEGIN(INITIAL);
<comment>"*)"+

"*)"                    { cool_yylval.error_msg = "Unmatched *)";
                          return (ERROR);
                        }



 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGNMENT}    { return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS_REG}     { return (CLASS); }
{ELSE_REG}      { return (ELSE); }
{FI_REG}        { return (FI); }
{IF_REG}        { return (IF); }
{IN_REG}        { return (IN); }
{INHERITS_REG}  { return (INHERITS); }
{LET_REG}       { return (LET); }
{LOOP_REG}      { return (LOOP); }
{POOL_REG}      { return (POOL); }
{THEN_REG}      { return (THEN); }
{WHILE_REG}     { return (WHILE); }
{CASE_REG}      { return (CASE); }
{ESAC_REG}      { return (ESAC); }
{OF_REG}        { return (OF); }
{NEW_REG}       { return (NEW); }
{ISVOID_REG}    { return (ISVOID); }
{NOT_REG}       { return (NOT); } 
{TRUE_REG}      { cool_yylval.boolean = true;
                  return (BOOL_CONST);
                }
{FALSE_REG}     { cool_yylval.boolean = false;
                  return (BOOL_CONST);
                }
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

{TYPE_ID}       { cool_yylval.symbol = inttable.add_string(yytext);
                  return (TYPEID);
                }

{OBJECT_ID}     { cool_yylval.symbol = inttable.add_string(yytext);
                  return (OBJECTID);
                }

\"              { string_buf_ptr = string_buf;
                  BEGIN(str);
                }

<str>\"         { BEGIN(INITIAL);
                  *string_buf_ptr = '\0';
                }

<str>\n         { return (ERROR); }

<str>\\[0-7]{1,3} {
                    int result;
     
                    (void) sscanf( yytext + 1, "%o", &result );
                           
                    if ( result > 0xff ) {
                        cool_yylval.error_msg = "Unescaped chars";
                        return (ERROR);
                    }
                    
                    *string_buf_ptr++ = result;
                  }

<str>\\[0-9]+   { return (ERROR); }

<str>\\n        *string_buf_ptr++ = '\n';
<str>\\t        *string_buf_ptr++ = '\t';
<str>\\r        *string_buf_ptr++ = '\r';
<str>\\b        *string_buf_ptr++ = '\b';
<str>\\f        *string_buf_ptr++ = '\f';

<str>\\(.|\n)   *string_buf_ptr++ = yytext[1];

<str>[^\\\n\"]+ {
                   char *yptr = yytext;
                         
                   while ( *yptr ) {
                           *string_buf_ptr++ = *yptr++;
                   }
                   
                   cool_yylval.symbol = inttable.add_string(yytext); 
                   return (STR_CONST);
                }



{DIGIT}         { cool_yylval.symbol = inttable.add_string(yytext); 
                  return (INT_CONST); 
                }

{PLUS_OP}       { return(43); }
{MINUS_OP}      { return(45); }
{MULT_OP}       { return(42); }
{DIV_OP}        { return(47); }


{SEMICOLON}     { return(59); }
{OPEN_PARA}     { return(40); }
{CLOSE_PARA}    { return(41); }
{OPEN_CURLY}    { return(123);}
{CLOSE_CURLY}   { return(125);}
{OPEN_BRACKET}  { return(91); }
{CLOSE_BRACKET} { return(93); }
{COLON}         { return(58); }         
{METHOD_ACCESS} { return(46); }
{GREATER}       { return(62); }
{LESS}          { return(60); }

{WHITE_SPACE}
{NEW_LINE}      { curr_lineno++; }
.               { return(ERROR); }
{NULL_CHAR}     { cool_yylval.error_msg = "Null char present.";
                  return(ERROR);
                }
