// semantics of shader program

#version version_number
in type in_variable_name; // input variable also known as vertex attribute
in type in_variable_name; // input variable also known as vertex attribute

out type out_variable_name; // output variable

uniform type uniform_name; // uniform variable

void main()
{
// process input(s) and do some weird graphics stuff
. . .
// output processed stuff to output variable
out_variable_name = weird_stuff_we_processed;
}
