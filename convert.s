;/*converting rax functions */

section .text 

;=============================================
;printing rax in hex                            
;--------------------------------------------
;Entry: rax = attr: value to print
;       rsi  = attr: buff addr to print in
;Exit: 
;Destroys: rbx, rcx, rdi, r10, r11
;--------------------------------------------
print_rax_x:   
                mov rcx, h_max_len          ; rcx = counter = max val len
                mov r10, h_mask             ;
                mov r11, h_max_len          ;
                                            ;
.next_x:        mov rbx, r10                ;
                and rbx, rax                ;
                                            ;
                mov r11, rcx                ;
                                            ;
.byte_in_bl:    cmp r11, 1                  ;
                je .end_bibl                ;
                                            ;
                shr rbx, 4                  ;
                dec r11                     ;
                jmp .byte_in_bl             ;
                                            ;
.end_bibl:                                  ;
                cmp bl, 9                   ;
                ja  .hex_val                ;
                                            ;
                mov byte [rsi], bl          ;
                add byte [rsi], '0'         ;
                inc rsi                     ;
                                            ;
                jmp .hex_next               ;
                                            ;
.hex_val:       sub bl, 10                  ;
                mov byte [rsi], bl          ;
                add byte [rsi], 'a'         ;
                inc rsi                     ;
.hex_next:     
                shr r10, 4                  ;
                loop .next_x                ;

                ret 
;=============================================

;=============================================
;printing rax in binary                            
;--------------------------------------------
;Entry: rax = attr: value to print
;       rsi  = attr: buff addr to print in
;Exit: 
;Destroys: rbx, rcx, rdx, rdi, rsi += val_len
;--------------------------------------------
print_rax_b:     
                mov rcx, b_max_len
                
.b_next:        dec cl              ; cl -= 1
                mov rdx, b_mask     ; dx = 1
                shl rdx, cl         ; dx *= 2^cl
                and rdx, rax        ; dx = dx and ax
                shr rdx, cl         ; dx /= 2^cl
                
                add dl, '0'         ; dx += '0'
                mov byte [rsi], dl    
                inc rsi
                inc cl

                loop .b_next 

                ret 
;=============================================

;=============================================
;printing rax in decimal (in reversed form)                           
;--------------------------------------------
;Entry: rax = attr: value to print
;       rsi  = attr: buff addr to print in
;Exit:  r11 = attr: val len
;       rsi = attr: next symb after val
;Destroys: rax = 0, rbx = 10, rcx, rdx
;--------------------------------------------
print_rax_d:     
                mov rcx, d_max_len
                mov r11, d_max_len
                mov rbx, d_mask 
                
.next:          xor rdx, rdx
                cmp rax, 0
                je .end 

                div rbx 
                mov byte [rsi], dl
                add byte [rsi], '0'

                inc rsi 
                loop .next 

.end:           sub r11, rcx 

                ret 
;=============================================

;=============================================
;printing rax in octal                          
;--------------------------------------------
;Entry: rax = attr: value to print
;       rsi  = attr: buff addr to print in
;Exit:  None
;Destroys: rbx, rcx, rsi, r11 
;--------------------------------------------
print_rax_o:     

                mov rcx, o_max_len
.next:          
                mov r11, rcx            ;save rcx in r11
                mov rbx, o_mask         ;rbx = 7
                dec rcx 
.shift:         
                cmp rcx, 0
                je .no_shift
                shl rbx, 3              ;-|shift on needed 3 bits  
                loop .shift             ;-|

                mov rcx, r11            ;rcx = saved
                dec rcx
                and rbx, rax            ;rbx = needed 3 bits of rax 
.unshift:                               
                shr rbx, 3              ;-|needed 3 bits to last 3 bits of rbx  
                loop .unshift           ;-|

                mov rcx, r11            ;rcx = saved

                mov byte [rsi], bl      ;-|*rsi = bl + '0'
                add byte [rsi], '0'     ;-|
                inc rsi 

                loop .next 
.no_shift:                              ;-| 
                and rbx, rax            ; |
                mov byte [rsi], bl      ; |no shift case (checking last 3 bytes)
                add byte [rsi], '0'     ; |
                inc rsi                 ;-|

                ret 
;=============================================


section .data 

h_max_len           equ 0x10
d_max_len           equ 0x14
o_max_len           equ 0x16
b_max_len           equ 0x40

h_mask              equ 0xF000000000000000
d_mask              equ 10 
o_mask              equ 0o7
b_mask              equ 0b1 