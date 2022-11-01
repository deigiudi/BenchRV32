/*
 *  SasRV32I -- A simple RISC-V (RV32I) Processor Core
 *  Copyright (c) 2020, Alessandro Dei Giudici <alessandro.deig@live.it>
 *  
 *  A file containing the TOP Architecture
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   
 *
 */

`timescale 1ns / 1ps

module TOP_RV32 (
//	output [31:0] oGPIO_OUT,
//	input  [31:0] iGPIO_IN,
	output oUART_TX,
	input	 iUART_RX,
	input	 exCLK,
	input	 iRST
);

// ClockWizard <=> ALL
wire iCLK;

// ICache <=> Core
wire [31:0] INSTADDR;
wire [31:0] INSTDATA;
wire [31:0] ICacheDATA;
wire ICacheStall;

// DCache <=> Core
wire RW; 
wire MEMTransaction;
wire DCacheStall;
wire [31:0] MEMADDR;
wire [31:0] MEMDATA;
wire [31:0] DCacheDATA;

clk_wiz CLK (
	.clk_out1(iCLK),
	.clk_in1(exCLK), 
	.reset(iRST)
	);

TOP_UART #(
   .t_CLKS_PER_BIT(115)
	) UART (
   .oRX_Byte(DCacheDATA[17:10]),
   .oRX_GotIt(DCacheDATA[9]),   
   .oTX_Done(DCacheDATA[8]),
   .oTX_Serial(oUART_TX),
   .iTX_Byte(DCacheDATA[7:0]),
   .iTX_Enable(1'h1),
   .iRX_Serial(iUART_RX),
   .iCLK(iCLK)	
	);


CacheCTRL CacheCTRL(	
	.oIcacheDATA(INSTDATA),
	.oDcacheDATA(MEMDATA),
	.iIcacheADDR(INSTADDR),
	.iDcacheADDR(MEMADDR[29:0]),
	.iStallI(ICacheStall),	
	.iStallD(DCacheStall),		
	.iCLK(iCLK)
	);

CacheI_RV32 #(
	.MEMSIZE(8)
	) CacheI (	
	.oStallI(ICacheStall),			// iCache hasn't got data needed
	.oINSTDATA(ICacheDATA),			// DATA OUT Destination Register	
	.iINSTDATA(INSTDATA),			// DATA IN Destination Register	
	.iINSTADDR(INSTADDR),			// ADDR IN Destination Register
	.iCLK(iCLK)
	);
	
CacheD_RV32 #(
	.MEMSIZE(8)
	) CacheD (
	.oStallD(DCacheStall),			// DCache hasn't got data needed
	.oMEMDATA(DCacheDATA),			// DATA OUT Memory
	.iMEMDATA(MEMDATA),				// DATA OUT Memory	
	.iMEMADDR(MEMADDR[29:0]),		// ADDR IN MEMORY
	.iMEM(MEMTransaction),			// There is a memory transaction to be performed	
	.iRW(RW),							// 1 = Read, 0 = Write
	.iCLK(iCLK)
	);
	
TOP_CoreRV32 Core (
	.oRW(RW),							// 1 = Read, 0 = Write
	.oMEM(MEMTransaction),			// There is a memory transaction to be performed
	.oINSTADDR(INSTADDR),			// Data Address to read from ICache
	.oMEMADDR(MEMADDR),				// ADDR OUT Memory
	.ioMEMDATA(DCacheDATA),			// DATA IN Memory
	.iINSTDATA(ICacheDATA),			// Instruction from ICache	
	.iStallI(ICacheStall),			// ICache hasn't got data needed = Bubble in pipeline
	.iStallD(DCacheStall),			// DCache hasn't got data needed = Bubble in pipeline		
	.iCLK(iCLK),
	.iRST(iRST)
	);

endmodule
