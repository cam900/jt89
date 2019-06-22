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
    SMS core of MiST. Some of the changes, all according to data sheet:

        -Fixed volume
        -Fixed tone 2 rate option of noise generator
        -Fixed rate of noise generator
        -Fixed noise shift clear
        -Fixed noise generator update bug by which it gets updated
            multiple times if v='0'
        -Added all 0's prevention circuit to noise generator

    */

module jt89_gg(
    input   clk,
(* direct_enable = 1 *) input   clk_en,
    input          rst,
    input          wr_n,
    input    [7:0] din,
    input    [7:0] pan,
    output  signed [10:0] sound_l,
    output  signed [10:0] sound_r,
    output         ready
);

parameter interpol16=0;

wire signed [ 8:0] ch0_l, ch1_l, ch2_l, noise_l, ch0_r, ch1_r, ch2_r, noise_r;

assign ready = 1'b1;
(* direct_enable = 1 *) reg cen_16;
(* direct_enable = 1 *) reg cen_4;

jt89_gg_mixer #(.interpol16(interpol16)) mix(
    .clk     ( clk     ),
    .clk_en  ( clk_en  ), // uses main clock enable
    .cen_16  ( cen_16  ),
    .cen_4   ( cen_4   ),
    .rst     ( rst     ),
    .pan     ( pan     ),
    .ch0_l   ( ch0_l   ),
    .ch0_r   ( ch0_r   ),
    .ch1_l   ( ch1_l   ),
    .ch1_r   ( ch1_r   ),
    .ch2_l   ( ch2_l   ),
    .ch2_r   ( ch2_r   ),
    .noise_l ( noise_l ),
    .noise_r ( noise_r ),
    .sound_l ( sound_l ),
    .sound_r ( sound_r )
);

// configuration registers
reg [9:0] tone0, tone1, tone2;
reg [3:0] vol0, vol1, vol2, vol3;
reg [2:0] ctrl3;
reg [2:0] regn;

reg [3:0] clk_div;

always @(negedge clk )
    if( rst ) begin
        cen_16 <= 1'b1;
        cen_4  <= 1'b1;
    end else begin
        cen_16 <= clk_en & (&clk_div);
        cen_4  <= clk_en & (&clk_div[1:0]);
    end

always @(posedge clk )
    if( rst )
        clk_div <= 4'd0;
    else if( clk_en )
        clk_div <= clk_div + 1'b1;

reg clr_noise, last_wr;
wire [2:0] reg_sel = din[7] ? din[6:4] : regn;

always @(posedge clk)
    if( rst ) begin
        { vol0, vol1, vol2, vol3 } <= {16{1'b1}};
        { tone0, tone1, tone2 } <= 30'd0;
        ctrl3 <= 3'b100;
    end
    else begin
        last_wr <= wr_n;
        if( !wr_n && last_wr ) begin
            clr_noise <= din[7:4] == 4'b1110; // clear noise
            // when there is an access to the control register
            regn <= reg_sel;
            case( reg_sel )
                3'b00_0: if( din[7] ) tone0[3:0]<=din[3:0]; else tone0[9:4]<=din[5:0];
                3'b01_0: if( din[7] ) tone1[3:0]<=din[3:0]; else tone1[9:4]<=din[5:0];
                3'b10_0: if( din[7] ) tone2[3:0]<=din[3:0]; else tone2[9:4]<=din[5:0];
                3'b11_0: ctrl3 <= din[2:0];
                3'b00_1: vol0  <= din[3:0];
                3'b01_1: vol1  <= din[3:0];
                3'b10_1: vol2  <= din[3:0];
                3'b11_1: vol3  <= din[3:0];
            endcase
        end
        else clr_noise <= 1'b0;
    end

jt89_tone u_tone0(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .vol    ( vol0      ),
    .tone   ( tone0     ),
    .snd    ( ch0_l     ),
    .out    (           )
);

jt89_tone u_tone1(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .vol    ( vol1      ),
    .tone   ( tone1     ),
    .snd    ( ch1_l     ),
    .out    (           )
);

wire out2_l;

jt89_tone u_tone2(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .vol    ( vol2      ),
    .tone   ( tone2     ),
    .snd    ( ch2_l     ),
    .out    ( out2_l    )
);

jt89_noise u_noise(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .clr    ( clr_noise ),
    .vol    ( vol3      ),
    .ctrl3  ( ctrl3     ),
    .tone2  ( tone2     ),
    .snd    ( noise_l   )
);

jt89_tone u_tone0(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .vol    ( vol0      ),
    .tone   ( tone0     ),
    .snd    ( ch0_r     ),
    .out    (           )
);

jt89_tone u_tone1(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .vol    ( vol1      ),
    .tone   ( tone1     ),
    .snd    ( ch1_r     ),
    .out    (           )
);

wire out2_r;

jt89_tone u_tone2(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .vol    ( vol2      ),
    .tone   ( tone2     ),
    .snd    ( ch2_r     ),
    .out    ( out2_r    )
);

jt89_noise u_noise(
    .clk    ( clk       ),
    .rst    ( rst       ),
    .clk_en ( cen_16    ),
    .clr    ( clr_noise ),
    .vol    ( vol3      ),
    .ctrl3  ( ctrl3     ),
    .tone2  ( tone2     ),
    .snd    ( noise_r   )
);

endmodule
