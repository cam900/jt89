/*  This file is part of JT89.

    JT89 is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JT89 is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JT89.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: March, 8th 2017
    
    This work was originally based in the implementation found on the
    SMS core of MiST
    
    */

module jt89_tone(
    input               clk,
(* direct_enable = 1 *) input   clk_en,
    input               rst,
    input         [9:0] tone,
    input         [3:0] vol,
    output signed [9:0] snd,
    output              out
);

reg [10:0] cnt;
assign out=cnt[10];
reg last_out;

jt89_vol u_vol(
    .rst    ( rst     ),
    .clk    ( clk     ),
    .clk_en ( clk_en  ),
    .din    ( out     ),
    .vol    ( vol     ),
    .snd    ( snd     )
);

reg do_load, inc;

always @(*) begin
    do_load = out!=last_out;
    inc     = tone!=10'd0;
end

always @(posedge clk) 
    if( rst ) cnt <= 11'd0;
    else if( clk_en ) begin
        last_out <= out;
        if( do_load ) begin 
            cnt[9:0] <= tone;
        end
        else cnt <= cnt- { 10'b0, inc };
    end

endmodule
