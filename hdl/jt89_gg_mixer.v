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
    Date: December, 1st 2018
   
    */

module jt89_gg_mixer #(parameter bw=9, interpol16=0)(
    input            rst,
    input            clk,
    input            clk_en,
    input            cen_16,
    input            cen_4,
    input            pan,
    input     [bw-1:0] ch0_l, ch0_r,
    input     [bw-1:0] ch1_l, ch1_r,
    input     [bw-1:0] ch2_l, ch2_r,
    input     [bw-1:0] noise_l, noise_r,
    output signed [bw+1:0] sound_l, sound_r
);

reg signed [bw+1:0] fresh_l, fresh_r;

always @(posedge clk) begin
    fresh_l <= 
        (pan[4] ? { {2{ch0_l[bw-1]}}, ch0_l   } : 0)+
        (pan[5] ? { {2{ch1_l[bw-1]}}, ch1_l   } : 0)+
        (pan[6] ? { {2{ch2_l[bw-1]}}, ch2_l   } : 0)+
        (pan[7] ? { {2{noise_l[bw-1]}}, noise_l } : 0);

    fresh_r <= 
        (pan[0] ? { {2{ch0_r[bw-1]}}, ch0_r   } : 0)+
        (pan[1] ? { {2{ch1_r[bw-1]}}, ch1_r   } : 0)+
        (pan[2] ? { {2{ch2_r[bw-1]}}, ch2_r   } : 0)+
        (pan[3] ? { {2{noise_r[bw-1]}}, noise_r } : 0);
    end

generate
    if( interpol16==1 ) begin
        wire signed [bw+1:0] snd4_l, snd4_r;
        localparam calcw=bw+8;
        jt12_interpol #(.calcw(calcw),.inw(bw+2),.rate(4),.m(4),.n(2)) u_uprate1l (
            .rst    ( rst     ),
            .clk    ( clk     ),
            .cen_in ( cen_16  ),
            .cen_out( cen_4   ),
            .snd_in ( fresh_l ),
            .snd_out( snd4_l  )
        );
        jt12_interpol #(.calcw(calcw),.inw(bw+2),.rate(4),.m(4),.n(2)) u_uprate2l (
            .rst    ( rst     ),
            .clk    ( clk     ),
            .cen_in ( cen_4   ),
            .cen_out( clk_en  ),
            .snd_in ( snd4_l  ),
            .snd_out( sound_l )
        );
        jt12_interpol #(.calcw(calcw),.inw(bw+2),.rate(4),.m(4),.n(2)) u_uprate1r (
            .rst    ( rst     ),
            .clk    ( clk     ),
            .cen_in ( cen_16  ),
            .cen_out( cen_4   ),
            .snd_in ( fresh_r ),
            .snd_out( snd4_r  )
        );
        jt12_interpol #(.calcw(calcw),.inw(bw+2),.rate(4),.m(4),.n(2)) u_uprate2r (
            .rst    ( rst     ),
            .clk    ( clk     ),
            .cen_in ( cen_4   ),
            .cen_out( clk_en  ),
            .snd_in ( snd4_r  ),
            .snd_out( sound_r )
        );
    end else begin
        assign sound_l = fresh_l;
        assign sound_r = fresh_r;
    end
endgenerate

endmodule