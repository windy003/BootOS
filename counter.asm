        ;
        ; 演示如何使用 bootOS 的服务
        ;
        ; 作者：Oscar Toledo G.
        ; http://nanochess.org/
        ;
        ; 创建日期：2019年7月31日
        ;

        org 0x7c00

        ;
        ; 这些段值和地址用于
        ; 测试 bootOS 的正确行为。
        ;
name_segment:    equ 0x1000
name_address:    equ 0x0100

data_segment:    equ 0x1100
data_address:    equ 0x0200

start:
        mov ax,name_segment
        mov es,ax

        mov si,name
        mov di,name_address
        mov bx,di
        mov cx,9
        rep movsb

        push es
        pop ds                  ; ds:bx 已准备好，指向文件名
        mov ax,data_segment
        mov es,ax
        mov di,data_address     ; es:di 已准备好，指向数据

        push bx
        push ds
        push di
        push es
        int 0x23                ; 加载文件。
        pop ds
        pop di
        push di
        push ds
        mov al,'*'              ; 文件存在。
        jnc .1
        mov al,'?'              ; 文件不存在。
        mov word [di],0x0000    ; 将计数器初始化为零。
.1:
        int 0x22                ; 输出字符。

        mov ax,[di]             ; 读取数据。

        inc al                  ; 增加右边的数字。
        cmp al,10               ; 是否等于 10？
        jne .2                  ; 否，则跳转。
        mov al,0                ; 重置为零。

        inc ah                  ; 增加左边的数字。
        cmp ah,10               ; 是否等于 10？
        jne .2                  ; 否，则跳转。
        mov ah,0                ; 重置为零。

.2:     mov [di],ax             ; 保存数据。

        push ax
        mov al,ah
        add al,'0'              ; 转换为 ASCII。
        int 0x22                ; 输出字符。
        pop ax

        add al,'0'              ; 转换为 ASCII。
        int 0x22                ; 输出字符。

        mov al,0x0d             ; 在屏幕上移动到下一行。
        int 0x22                ; 输出字符。

        pop es
        pop di
        pop ds
        pop bx
        int 0x24                ; 保存文件。

        int 0x20                ; 返回 bootOS。

name:   db "data.bin",0         ; 文件名。

