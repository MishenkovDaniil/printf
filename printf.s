section .text

global _start 

_start:     mov rax, [param1]
            push rax
            push rax
            push rax
            push rax

            mov rax, printing_str
            push rax 
            call printf 
            pop rax 
            
            pop rax
            pop rax
            pop rax 
            pop rax  

            mov rax, 0x3c   ;-|
            xor rdi, rdi    ; | exit (rdi = 0)
            syscall         ;-|

;--------------------------------------------
;cdecl printf (const char *format,...)                               
;--------------------------------------------
;Entry: stack 
;Exit: 
;Destroys: rax, rcx, rdx, rsi, rdi, r9, r10, r11 
;--------------------------------------------
printf:     
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
                cmp rcx, max_str_len    ;-|if (rcx >= max_str_len)
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

;--------------------------------------------
;error format treatment
;--------------------------------------------
;Entry:
;Exit:
;Destroys:
;--------------------------------------------
printf_default:
                ;error
                ret 
;--------------------------------------------

;--------------------------------------------
;auxilary func for printf: printing %c                               
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;Exit: 
;Destroys: rsi, rdi += 1, r9 
;--------------------------------------------
printf_c:   
            push rsi 
            mov rsi, [r9]          ;rax = first untreated parameter (%c)
            movsb
            add r9, 8              ;r9 to next parameter
            pop rsi 

            ret 

;--------------------------------------------
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
;--------------------------------------------
    
;--------------------------------------------
;auxilary func for printf: printing %b                               
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;Exit: 
;Destroys: rax = val, rbx, rcx += val_len + 2,
;          rdx, rdi += val_len + 2, r9 += 8
;--------------------------------------------
printf_b:   
            push rsi 
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
            mov rbx, rcx 

            rep movsb 
            
            pop rcx 
            add rcx, rbx 
            add rcx, 2
            pop rsi 

            add r9, 8

            ret  
;--------------------------------------------

;--------------------------------------------
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

;--------------------------------------------

;--------------------------------------------
;auxilary func for printf: printing %d                              
;--------------------------------------------
;Entry: r9  = attr: pointer for first untreated parameter  
;       rdi = attr: printf buff addr
;       rcx = attr: buff len (< 0xF5)
;Exit:  rcx = new buff_len 
;Destroys: rax, rbx, rdx, rdi, r9, r11
;--------------------------------------------
printf_d:   
            push rsi 
            push rcx
            
            mov rax, [r9] 
            
            mov rsi, val_buff
            call print_rax_d
            dec rsi 

            mov rcx, r11 

.next:      movsb           
            sub rsi, 2      ;because of reverted val in buff 
    
            loop .next 
            
            pop rcx 
            add rcx, r11 
            pop rsi 

            add r9, 8

            ret  
;--------------------------------------------


;--------------------------------------------
;auxilary for printf: prints string (%s)
;--------------------------------------------
;Entry: 
;Exit:  
;Destroys: None
;--------------------------------------------
printf_s:        

                if strlen ([r9]) > max_str_len --> write() string
                if strlen ([r9]) > max_str_len - rcx --> put str in buff while it is possible, than write() buff and put str in buff 
                else put str in buff 

                ret 
;--------------------------------------------

;--------------------------------------------
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
;--------------------------------------------


%include 'convert.s'

section .data  

max_str_len         equ 0xF5

printing_str:       db " %o %d %x %b $", 0
param1:             dq 505
param2:             db "hello hello", 0


printf_buff:        db 0xFF dup (0)
val_buff:           db 0x40 dup (0)



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



;code map  посмотреть и горяие клавиши ida  
 