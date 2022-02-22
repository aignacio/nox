#! /usr/bin/env python3
# Copyright https://github.com/aignacio
import argparse
import sys
import math

def gen_rom(hex, rom_mem):
    address_width = math.ceil(math.log(sum(1 for line in hex),2));
    rom_mem.write("module boot_rom (\n");
    rom_mem.write("  input          clk,\n");
    rom_mem.write("  input          en,\n");
    rom_mem.write("  input  [%d:0]  addr_i,\n" % (address_width-1));
    rom_mem.write("  output [31:0]  dout_o\n");
    rom_mem.write(");\n\n");
    rom_mem.write(" // Based on this UG - https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_1/ug901-vivado-synthesis.pdf\n\n")
    rom_mem.write(" (*rom_style = \"block\" *) logic [31:0] data;\n");
    rom_mem.write(" assign dout_o = data;\n\n");
    rom_mem.write(" always @(posedge clk) begin\n");
    rom_mem.write("     if (en) begin\n");
    rom_mem.write("         case (addr_i)\n");
    hex.seek(0);
    hex_lines = hex.readlines()[:-1]
    hex.seek(0);
    last_line = hex.readlines()
    index = 0
    for line in hex_lines:
        rom_mem.write("         'd"+str(index)+": data <= 32\'h"+line.rstrip()+";");
        index += 1
        if index%2 == 0:
            rom_mem.write("\n")
    rom_mem.write("         'd"+str(index)+": data <= 32\'h"+last_line[-1].rstrip()+";");
    rom_mem.write("\n")
    rom_mem.write("         default: data <= '0;\n")
    rom_mem.write("         endcase\n");
    rom_mem.write("     end\n");
    rom_mem.write(" end\n");
    rom_mem.write("endmodule\n");

# def gen_rom_xilinx(hex, rom_mem):
#     address_width = math.ceil(math.log(sum(1 for line in hex),2));
#     rom_mem.write("module boot_rom_generic (\n");
#     rom_mem.write("  input   rst_n,\n");
#     rom_mem.write("  input   clk,\n");
#     rom_mem.write("  input   [%d:0] raddr_i,\n" % (address_width-1));
#     rom_mem.write("  output  [31:0] dout_o\n");
#     rom_mem.write(");\n\n");
#     rom_mem.write("(\*rom_style = \"block\" \*) reg [0:%d] [31:0] mem_array;\n\n" % (2**(address_width)-1));
#     rom_mem.write("  always @(posedge clk)\n");
#     rom_mem.write("     case(raddr_i)\n");
#     hex.seek(0);
#     address_index = 0;
#     for line in hex:
#         rom_mem.write("         %d\'h\n" % (line.rstrip()));
#         address_index += 1;
#     rom_mem.write("     endcase\n\n");
#     rom_mem.write("assign dout_o = mem_array;\n\n");
#     rom_mem.write("endmodule\n");

def main():
    parser = argparse.ArgumentParser(
        description='Convert a hexadecimal program file into behavioral rom memory.'
    )
    if sys.version_info >= (3, 0):
        parser.add_argument('--in_hex',
                            help="Input file in hex format compatible with $readmemh - 32bits/line",
                            nargs='?',
                            type=argparse.FileType('r'),
                            default=sys.stdin.buffer)
    else:
        parser.add_argument('--in_hex',
                            help="Input file in hex format compatible with $readmemh - 32bits/line",
                            nargs='?',
                            type=argparse.FileType('rb'),
                            default=sys.stdin)

    parser.add_argument('--out_v',
                        help="Output file with in verilog of the behavioral ROM memory ",
                        nargs='?',
                        type=argparse.FileType('w'),
                        default=sys.stdout)

    args = parser.parse_args()
    gen_rom(args.in_hex, args.out_v)

if __name__ == '__main__':
    main()
