iverilog -o output -c file_list.txt ./components/fulladder.v ./components/test.v &&
vvp output
