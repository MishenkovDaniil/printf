section .text

global strt_printf 

extern printf 


;==============================================
;==============================================
strt_printf:    
                pop qword [ret_addr]
                
                push r9 
                push r8 
                push rcx 
                push rdx
                push rsi  
                push rdi  

                call printf_main 

                pop rdi 
                pop rsi 
                pop rdx 
                pop rcx 
                pop r8 
                pop r9 

                call printf 

                push qword [ret_addr]

                ret
;==============================================
;==============================================

;=============================================
;__cdecl printf (const char *format,...)                               
;--------------------------------------------
;Entry: RSP on format 
;Exit: None
;Destroys: rax, rcx, rdx, rsi, rdi, r9, r10, r11 
;--------------------------------------------
printf_main:     
                mov r9, rsp             ;-|r9 on first stack arg
                add r9, 8               ;-|           
                mov rdx, [r9]           ;rdx = format 
                add r9, 8               ;r9 to next param

.print_start:
                mov rdi, printf_buff    ;buff for current string storage before calling write()
                
                mov al, '%'             ;symbol to compare with  
                
                mov rsi, rdx            ;rsi = format
                xor rcx, rcx            ;rcx = 0

.next:      
                cmp rcx, MAX_STR_LEN    ;-|if (rcx >= max_str_len)
                jnb .print_str          ;-|     goto .print_str

                cmp byte [rsi], 0       ;-|check if format ends 
                je .format_end          ;-|

                cmp byte [rsi], al      ;-|if *(rsi) == '%'
                je .percent_switch      ;-|     goto .jmp_table

                movsb                   ;*buff++ = *rsi++
                inc rcx                 ;++counter (rcx)

                jmp .next               ; goto .next


.percent_switch:  
                inc rsi                 ;++rsi
                cmp byte [rsi], al      ;if *(rsi) == '%'
                je .print_percent       ;   goto .print_percent
                
                xor r10, r10            ;-|r10 = *rsi 
                or r10b, byte [rsi]     ;-|

                cmp r10, 0x62           ;-|
                jb printf_default       ; |error percent treating
                cmp r10, 0x78           ; |
                ja printf_default       ;-|
                sub r10, 0x62           ;r10 -= 0x63 for jmp_table

                call percent_jmp_table[r10*8] ;call % func
                inc rsi                 ;skip format char

                mov al, '%'             ;as functions may destroy al, we reinit it
                
                jmp .next               ;goto next

.print_percent:             
                movsb                   ;*buff++ = *rsi++
                inc rcx                 ;++counter (rcx)

                jmp .next               ; goto .next

.print_str: 
                push rsi                ;push curr format addr 

                mov rax, 0x01           ;-|
                mov rdi, 1              ; |
                mov rsi, printf_buff    ; |write buff  
                mov rdx, rcx            ; |
                syscall                 ;-|

                pop rdx                 ;pop curr format addr in rdx 

                jmp .print_start

.format_end:    mov rax, 0x01                
                mov rdi, 1
                mov rsi, printf_buff 
                mov rdx, rcx
                syscall

                ret 
;=============================================

;=============================================
;error format treatment
;--------------------------------------------
;Entry: rsi = attr: on error char
;Exit: rsi++, rdi++, rcx++
;Destroys: None
;--------------------------------------------
printf_default:
                movsb 
                inc rcx
                ret 
;=============================================


;=============================================
;auxilary func for printf: printing %c                               
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;Exit: 
;Destroys: rsi, rdi += 1, r9 += 8
;--------------------------------------------
printf_c:   
            push rsi 

            mov rsi, r9            ;rax = first untreated parameter (%c)
            movsb
            add r9, 8              ;r9 to next parameter
            
            pop rsi 
            inc rcx 

            ret 
;=============================================

;=============================================
;auxilary func for printf: printing %x                               
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;Exit: 
;Destroys: rax = val, rbx, rdi += val_len, r9 += 8, r10, r11
;--------------------------------------------
printf_x:   
            push rsi
            push rcx 

            mov rax, [r9] 
            
            mov byte [rdi], '0'
            inc rdi
            mov byte [rdi], 'x'
            inc rdi 

            mov rsi, val_buff
            call print_rax_x
            mov rsi, val_buff

            mov rcx, 0x10
            call skip_zeroes
            mov rbx, rcx 
            rep movsb 

            add r9, 8

            pop rcx 
            add rcx, rbx 
            add rcx, 2 
            pop rsi 

            ret           
;=============================================
    
;=============================================
;auxilary func for printf: printing %b                               
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;Exit: 
;Destroys: rax, rbx, rcx = new buff len,
;          rdx, rdi = curr buff addr, r9 += 8
;--------------------------------------------
printf_b:   
            push rsi 
            push rcx 
            push rcx 
            
            mov rax, [r9] 

            mov byte [rdi], '0'
            inc rdi 
            mov byte [rdi], 'b'
            inc rdi 

            mov rsi, val_buff
            call print_rax_b
            mov rsi, val_buff
            
            mov rcx, 0x40
            call skip_zeroes
            
            mov rbx, MAX_STR_LEN    ;-|
            pop rdx                 ; | 
            sub rbx, rdx            ; |if (val_len > max_buff_len - buff_len)   goto no_free_place
            cmp rcx, rbx            ; |
            ja .no_free_place       ;-|

            mov rbx, rcx 

            rep movsb 
            
            pop rcx 
            add rcx, rbx 
            add rcx, 2
            pop rsi 

            jmp .end 

.no_free_place:
            mov rdx, rcx 
            sub rdx, rbx

            mov rcx, rbx 

            rep movsb 
            mov r10, rsi 

            pop rcx 

            mov rax, rdx    ;-| 
            mov rdx, rbx    ; |swap rdx and rbx
            add rdx, rcx    ; |rdx += buff len
            mov rbx, rax    ;-|

            mov rax, 0x01 
            mov rdi, 1
            mov rsi, printf_buff 
            syscall 

            mov rcx, rbx 
            mov rsi, r10
            mov rdi, printf_buff 

            rep movsb 

            mov rcx, rbx 

            pop rsi 

.end:
            add r9, 8

            ret  
;=============================================

;=============================================
;auxilary func for printf: printing %o                               
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;       rcx = buff len 
;Exit:  rcx = new buff len
;Destroys: rax, rbx, r9 += 8, r11
;--------------------------------------------
printf_o:   
            push rsi 
            push rcx 
            
            mov rax, [r9] 
            
            mov byte [rdi], '0'
            inc rdi 
            mov byte [rdi], 'o'
            inc rdi 

            mov rsi, val_buff
            call print_rax_o
            mov rsi, val_buff

            mov rcx, 0x16
            call skip_zeroes
            mov rbx, rcx 

            rep movsb

            pop rcx 
            add rcx, rbx 
            add rcx, 2

            pop rsi 

            add r9, 8

            ret   
;=============================================


;=============================================
;auxilary func for printf: printing %d                              
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;       rcx = attr: buff len (< 0xF5)
;Exit:  rcx = new buff_len 
;Destroys: rax, rbx, rdx, rdi, r9, r10, r11
;--------------------------------------------
printf_d:   
            push rsi 
            push rcx
            
            xor r10, r10

            mov rax, [r9] 
            test rax, rax 


            jns .positive_num   ;-|
            mov byte [rdi], '-' ; |if num is negative print '-'
            inc rdi             ;-|
            neg rax 

            inc r10

.positive_num:
            mov rsi, val_buff
            call print_rax_d
            dec rsi 

            mov rcx, r11 

.next:      movsb           
            sub rsi, 2      ;because of reverted val in buff 
    
            loop .next 
            
            pop rcx 
            add rcx, r11 
            add rcx, r10 
            pop rsi 

            add r9, 8

            ret  
;=============================================


;=============================================
;auxilary for printf: prints string (%s)
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter
;       rdi = attr: printf buff addr
;       rcx = attr: buff len (< 0xF5)
;Exit:  rcx = new buff len
;       rdi = curr buff addr
;Destroys: rax, rbx, rdx, rsi, r9 += 8, r10
;--------------------------------------------
printf_s:        
                push rsi
                push rcx 
                push rdi 

                mov rbx, rcx  
                
                mov rdi, [r9]

                call strlen 

                cmp rcx, MAX_STR_LEN    ;-|if strlen ([r9]) > max_str_len -->write() buff and  write() string
                ja .write_str           ;-|
                 
                mov r10, rbx            ;-|
                mov rbx, MAX_STR_LEN    ; |rbx = max_len - rbx
                sub rbx, r10            ;-|
               ;; xor rbx, MAX_STR_LEN    ;-|
                cmp rcx, rbx            ; |if strlen ([r9]) > max_str_len - rcx --> put str in buff while it is possible, than write() buff and put str in buff 
                ja .write_buff          ;-|
                                        ;(else put str in buff)

                mov rdx, rcx            ;-|save str len in rdx

                mov rsi, rdi            ;rsi = addr of string
                pop rdi                 ;rdi = buff addr

                rep movsb               ;while (rcx)  *rdi++ = *rsi++

                pop rcx                 ;-|rcx = old counter + str len
                add rcx, rdx            ;-|

                pop rsi 

                jmp .end 

.write_str:     
                pop r10 
                mov r10, rdi 
                mov rbx, rcx 

                mov rax, 0x01           ;-|
                mov rdi, 1              ; |
                mov rsi, printf_buff    ; |write() buff
                pop rdx                 ; |
                syscall                 ;-|
                
                mov rax, 0x01
                mov rsi, r10            ;-| 
                mov rdx, rbx            ; |write() string
                syscall                 ;-|

                xor rcx, rcx  
                mov rdi, printf_buff

                pop rsi 

                jmp .end 

.write_buff:    
                mov r10, rcx            ;save rcx in r10
                sub r10, rbx            ;r10 -=printed len 
                mov rcx, rbx            ;rcx = max_buff_len - buff_len

                mov rsi, rdi            ;rsi = str addr
                pop rdi                 ;rdi = buff addr

                rep movsb               ;while (rcx) *rdi++ = *rsi++

                push rsi                ;push curr string addr
  
                mov rax, 0x01           ;-|
                mov rdi, 1              ; |
                mov rsi, printf_buff    ; |write() buff 
                mov rdx, MAX_STR_LEN    ; |
                syscall                 ;-|

                pop rsi 
                pop rcx                 ;-|rcx = len of unprinted str
                mov rcx, r10            ;-|
                mov rdi, printf_buff 

                rep movsb 

                mov rcx, r10            ;rcx = len of buff

                pop rsi 

.end:           
                add r9, 8
                
                
                ret 
;=============================================



;=============================================
;counts ctring len (up to 0)
;--------------------------------------------
;Entry: rdi = attr: start string addr 
;Exit:  rcx = attr: str len 
;Destroys: al = 0, r10 = rdi
;--------------------------------------------
strlen:    
                cld 
                
                mov r10, rdi 
                mov al, 0

                mov rcx, LONG_LONG_MAX
                repne scasb
                xor rcx, LONG_LONG_MAX
                dec rcx 

                mov rdi, r10 

                ret 
;=============================================


;=============================================
;skips unnecessary zeroes in first rax bytes of mem
;--------------------------------------------
;Entry: rcx = attr: num of bytes to check 
;       rsi = attr: addr of mem start 
;Exit:  rsi on first meaning val, 
;       rcx = attr: num of remaining symbols 
;Destroys: None
;--------------------------------------------
skip_zeroes:    
                cld 

.next:          cmp byte [rsi], '0'
                jne .end 
                inc rsi 
                loop .next 
.end:
                ret 
;=============================================


%include 'convert.s'

section .data  

LONG_LONG_MAX       equ 0xffffffffffffffff
MAX_STR_LEN         equ 0xe9

printing_str:       db "ssdnsjdsdsndg  %d %c fdsdz", 0
param1:             db 'f'
param3:             dq 14
param2:             db "heo", 0


ret_addr:           dq 0

printf_buff:        db 0xFF dup (0)
val_buff:           db 0x40 dup (0)

;'-' перед каждым словом, "%d %b %x %d%%%c%d"
;
;
;
;
;stdcall: asm from c and c from asm


section .rodata align = 8            ;alignment addr on 8 byte

percent_jmp_table:
    dq               printf_b
    dq               printf_c     
    dq               printf_d     
    times 10    dq   printf_default 
    dq               printf_o 
    times 3     dq   printf_default 
    dq               printf_s 
    times 4     dq   printf_default
    dq               printf_x

 