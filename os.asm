;
        ; bootOS，一个仅 512 字节的操作系统
        ;
        ; 作者：Oscar Toledo G.
        ; http://nanochess.org/
        ;
        ; 创建日期：2019年7月21日 下午6点 - 晚上10点
        ; 修订日期：2019年7月22日 优化、修正和注释。
        ; 修订日期：2019年7月31日 增加了服务表，并允许
        ;                        文件名/源/目标位于任意段中。
        ;                        'del' 命令现在会显示错误。
        ;

        cpu 8086

        ;
        ; 什么是 bootOS：
        ;
        ;   bootOS 是一个单体（monolithic）操作系统，能够容纳在
        ;   一个引导扇区中。它能够加载、执行并保存
        ;   程序。同时它维护一个文件系统。它可以适用于
        ;   任何大小不小于 180K 的软盘。
        ;
        ;   它会把自己重定位到 0000:7a00，并需要额外的
        ;   768 字节内存，从 0000:7700 开始。
        ;
        ;   该操作系统把程序作为引导扇区运行于
        ;   0000:7c00。
        ;
        ;   它提供以下服务：
        ;      int 0x20   退出到操作系统。
        ;      int 0x21   输入按键并显示在屏幕上。
        ;                 入口：无
        ;                 输出：AL = 按下的 ASCII 键。
        ;                 影响：AH/BX/BP。
        ;      int 0x22   向屏幕输出字符。
        ;                 入口：AL = 字符。
        ;                 输出：无。
        ;                 影响：AH/BX/BP。
        ;      int 0x23   加载文件。
        ;                 入口：DS:BX = 以零结尾的文件名。
        ;                        ES:DI = 指向源数据（512 字节）
        ;                 输出：进位标志 = 0 = 找到，1 = 未找到。
        ;                 影响：所有寄存器（包括 ES）。
        ;      int 0x24   保存文件。
        ;                 入口：DS:BX = 以零结尾的文件名。
        ;                        ES:DI = 指向数据目标（512 字节）
        ;                 输出：进位标志 = 0 = 成功。1 = 错误。
        ;                 影响：所有寄存器（包括 ES）。
        ;      int 0x25   删除文件。
        ;                 入口：DS:BX = 以零结尾的文件名。
        ;                 影响：所有寄存器（包括 ES）。
        ;
        ;
        ; 文件系统组织：
        ;
        ;   bootOS 使用磁道 0 到 32，0 面，扇区 1。
        ;
        ;   目录存放在磁道 0，0 面，扇区 2。
        ;
        ;   目录中的每个条目宽 16 字节，包含
        ;   以零字节结尾的 ASCII 文件名。一个扇区的
        ;   容量为 512 字节，这意味着一张软盘上
        ;   只能保存 32 个文件。
        ;
        ;   删除一个文件就是将整个条目清零。
        ;
        ;   每个文件长度为一个扇区。它在磁盘上的
        ;   位置由它在目录中的位置推导出来。
        ;
        ;   第 1 个文件位于磁道 1，0 面，扇区 1。
        ;   第 2 个文件位于磁道 2，0 面，扇区 1。
        ;   第 32 个文件位于磁道 32，0 面，扇区 1。
        ;
        ;
        ; 启动 bootOS：
        ;
        ;   只需确保将它写入软盘的引导扇区即可。
        ;   它可以适用于任何大小的软盘
        ;   （360K、720K、1.2MB 和 1.44MB），并且会浪费
        ;   磁盘空间，因为它只使用磁盘的前两个扇区，
        ;   然后是之后每个磁道的第一个扇区。
        ;
        ;   对于模拟，请确保将它放置在 360K、720K 或
        ;   1440K 的 .img 文件的开头处。（至少
        ;   VirtualBox 是通过镜像文件的长度来检测
        ;   磁盘类型的）
        ;
        ;   对于 Mac OS X 和 Linux，你可以这样创建一个
        ;   360K 的镜像：
        ;
        ;     dd if=/dev/zero of=oszero.img count=719 bs=512
        ;     cat os.img oszero.img >osbase.img
        ;
        ;   对于 720K 用 1439 替换 719，对于 1.44M 用 2879 替换。
        ;
        ;   在运行 Windows XP 的 Mac OS X 上用 VirtualBox 测试过，
        ;   它也可以在 qemu 上运行：
        ;
        ;     qemu-system-x86_64 -fda os.img
        ;
        ; 运行 bootOS：
        ;
        ;   第一次你应该输入 'format' 命令，
        ;   这样它会初始化目录。它还会把自己
        ;   再次复制到引导扇区，这对于初始化新
        ;   磁盘很有用。
        ;
        ; bootOS 命令：
        ;
        ;   ver           显示版本（目前没有）
        ;   dir           显示目录内容。
        ;   del filename  删除 "filename" 文件。
        ;   format        如前所述。
        ;   enter         允许输入最多 512 个十六进制
        ;                 字节以创建另一个文件。
        ;
        ;                 注意每行大小为 128 个字符，所以
        ;                 你必须将输入分成
        ;                 4、8 或 16 字节的块。
        ;
        ;                 它还允许复制上一个执行过的
        ;                 程序，只需在出现 'h' 提示符时
        ;                 按回车并输入新名称。
        ;
        ; 例如：（字符 + 表示回车键）
        ;
        ;   $enter+
        ;   hbb 17 7c 8a 07 84 c0 74 0c 53 b4 0e bb 0f 00 cd+
        ;   h10 5b 43 eb ee cd 20 48 65 6c 6c 6f 2c 20 77 6f+
        ;   h72 6c 64 0d 0a 00+
        ;   h+
        ;   *hello+
        ;   $dir+
        ;   hello
        ;   $hello+
        ;   Hello, world
        ;   $
        ;
        ; bootOS 程序：（没错！我们有软件支持）
        ;
        ;   fbird         https://github.com/nanochess/fbird
        ;   Pillman       https://github.com/nanochess/pillman
        ;   invaders      https://github.com/nanochess/invaders
        ;   bootBASIC     https://github.com/nanochess/bootBASIC
        ;
        ; 你可以使用 'enter' 命令直接复制机器码，
        ; 或者你可以用同一命令创建一个带有签名字节的
        ; 文件，然后利用签名字节作为线索在镜像文件中
        ; 定位正确的位置，再把二进制文件复制进
        ; .img 文件中。
        ;
        ; 或者你可以在这个 Git 中找到一个预先设计好的
        ; 磁盘镜像，名为 osall.img
        ;

stack:  equ 0x7700      ; 栈指针（向低地址增长）
line:   equ 0x7780      ; 行输入缓冲区
sector: equ 0x7800      ; 目录的扇区数据
osbase: equ 0x7a00      ; bootOS 的位置
boot:   equ 0x7c00      ; 引导扇区的位置

entry_size:     equ 16  ; 目录条目大小
sector_size:    equ 512 ; 扇区大小
max_entries:    equ sector_size/entry_size

;
        ; bootOS 的冷启动
        ;
        ; 注意它被加载到 0x7c00（boot），并需要把自己
        ; 重定位到 0x7a00（osbase）。'start' 和
        ; 'ver_command' 之间的指令不应依赖于
        ; 汇编位置（osbase），因为它们是
        ; 在引导位置（boot）运行的。
        ;
        org osbase
start:
        xor ax,ax       ; 将所有段寄存器设为零
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov sp,stack    ; 设置栈以保证数据安全

        cld             ; 清除 D 标志。
        mov si,boot     ; 复制 bootOS 引导扇区...
        mov di,osbase   ; ...到 osbase
        mov cx,sector_size
        rep movsb

        ; 注意：通过调整上面复制的长度，我们本可以
        ; 避免在此处设置 SI 的需要，但那样
        ; 会破坏 'format' 命令。
        mov si,int_0x20 ; SI 现在指向 int_0x20
        mov di,0x0020*4 ; int 0x20 服务的地址
        mov cl,6
.load_vec:
        movsw           ; 复制 IP 地址
        stosw           ; 复制 CS 地址
        loop .load_vec

        ;
        ; 'ver' 命令
        ;
ver_command:
        mov si,intro
print_then_restart:
        call output_string
        int int_restart ; 重启 bootOS

        ;
        ; bootOS 的热启动
        ;
restart:
        cld             ; 清除 D 标志。
        push cs         ; 重新初始化所有段寄存器
        push cs
        push cs
        pop ds
        pop es
        pop ss
        mov sp,stack    ; 重启栈

        mov al,'$'      ; 命令提示符
        call input_line ; 输入一行

        cmp byte [si],0x00  ; 是空行吗？
        je restart          ; 是，则获取另一行

        mov di,commands ; 指向命令列表

        ; 注意以相同字符开头的文件名
        ; 不会被这样识别（所以文件 dirab 不能
        ; 被执行）。
os11:
        mov cl,[di]     ; 读取命令的字符长度
        inc di
        xor ch, ch      ; 同时确保 ZF = 1
        push si         ; 保存当前位置
        rep cmpsb       ; 比较语句
        jne os14        ; 相等吗？不，则跳转
        call word [di]  ; 调用命令处理程序
        jmp restart     ; 去等待另一个命令

os14:   add di,cx       ; 推进列表指针
        scasw           ; 跳过地址
        pop si
        jmp os11        ; 比较另一个语句

exec_from_disk:
        pop bx
        pop bx
        mov di,boot     ; 读取数据的位置
        int int_load_file       ; 加载文件
        jc os7          ; 出错则跳转
        jmp bx

        ;
        ; 文件未找到错误
        ;
os7:
        mov si,error_message
        jmp print_then_restart

        ;
        ; >> 命令 <<
        ; del filename
        ;
del_command:
os22:
        mov bx,si       ; 将 SI（缓冲区指针）复制到 BX
        lodsb
        cmp al,0x20     ; 跳过空格
        je os22
        int int_delete_file
        jc os7
        ret

        ;
        ; 'dir' 命令
        ;
dir_command:
        call read_dir           ; 读取目录
        mov di,bx
os18:
        cmp byte [di],0         ; 是空条目吗？
        je os17                 ; 是，则跳转
        mov si,di               ; 指向数据
        call output_string      ; 显示名称
os17:   call next_entry
        jne os18                ; 不是，则跳转
        ret                     ; 返回

        ;
        ; 获取文件名长度并为目录查找做准备
        ; 入口：
        ;   si = 指向字符串的指针
        ; 输出：
        ;   si = 不受影响
        ;   di = 指向目录起始位置的指针
        ;   cx = 文件名长度（包括零结尾符）
        ;
filename_length:
        push si
        xor cx,cx       ; cx = 0
.loop:
        lodsb           ; 读取字符。
        inc cx          ; 计数字符。
        cmp al,0        ; 是零（结束字符）吗？
        jne .loop       ; 不是，则跳转。

        pop si
        mov di,sector   ; 指向目录起始位置。
        ret

        ;
        ; >> 服务 <<
        ; 加载文件
        ;
        ; 入口：
        ;   ds:bx = 指向以零字节结尾的文件名的指针。
        ;   es:di = 目标。
        ; 输出：
        ;   进位标志 = 置位 = 未找到，清除 = 成功。
        ;
load_file:
        push di         ; 保存目标
        push es
        call find_file  ; 查找文件（会清理 ES）
        mov ah,0x02     ; 读取扇区
shared_file:
        pop es
        pop bx          ; 在 BX 中恢复目标
        jc ret_cf       ; 出错则跳转
        call disk       ; 对磁盘执行操作
                        ; 保证进位标志被清除。
ret_cf:
        mov bp,sp
        rcl byte [bp+4],1       ; 把进位标志插入到 Flags 中（自动使用 SS）
        iret

        ;
        ; >> 服务 <<
        ; 保存文件
        ;
        ; 入口：
        ;   ds:bx = 指向以零字节结尾的文件名的指针。
        ;   es:di = 源。
        ; 输出：
        ;   进位标志 = 置位 = 错误，清除 = 正常。
        ;
save_file:
        push di                 ; 保存源
        push es
        push bx                 ; 保存文件名指针
        int int_delete_file     ; 删除之前的文件（会清理 ES）
        pop bx                  ; 恢复文件名指针
        call filename_length    ; 为查找做准备

.find:  es cmp byte [di],0      ; 找到空目录条目了吗？
        je .empty               ; 是，则跳转并填充它。
        call next_entry
        jne .find
        jmp shared_file

.empty: push di
        rep movsb               ; 将完整名称复制到目录中
        call write_dir          ; 保存目录
        pop di
        call get_location       ; 获取文件位置
        mov ah,0x03             ; 写入扇区
        jmp shared_file

        ;
        ; >> 服务 <<
        ; 删除文件
        ;
        ; 入口：
        ;   ds:bx = 指向以零字节结尾的文件名的指针。
        ; 输出：
        ;   进位标志 = 置位 = 未找到，清除 = 已删除。
        ;
delete_file:
        call find_file          ; 查找文件（会清理 ES）
        jc ret_cf               ; 若进位置位则未找到，跳转。
        mov cx,entry_size
        call write_zero_dir     ; 将整个条目填零。写入目录。
        jmp ret_cf

        ;
        ; 查找文件
        ;
        ; 入口：
        ;   ds:bx = 指向以零字节结尾的文件名的指针。
        ; 输出：
        ;   es:di = 指向目录条目的指针
        ;   进位标志 = 找到则清除，未找到则置位。
find_file:
        push bx
        call read_dir   ; 读取目录（会清理 ES）
        pop si
        call filename_length    ; 获取文件名长度并设置 DI
os6:
        push si
        push di
        push cx
        repe cmpsb      ; 将名称与条目比较
        pop cx
        pop di
        pop si
        je get_location ; 相等则跳转。
        call next_entry
        jne os6         ; 不是，则跳转
        ret             ; 返回

next_entry:
        add di,byte entry_size          ; 前往下一个条目。
        cmp di,sector+sector_size       ; 目录是否完成？
        stc                             ; 错误，未找到。
        ret

        ;
        ; 获取文件在磁盘上的位置
        ;
        ; 入口：
        ;   DI = 指向目录中条目的指针。
        ;
        ; 输出：
        ;   CH = 磁盘中的磁道号。
        ;   CL = 扇区（始终为 0x01）。
        ;
        ; 文件在磁盘内的位置取决于它
        ; 在目录中的位置。第一个条目位于
        ; 磁道 1，第二个条目位于磁道 2，依此类推。
        ;
get_location:
        lea ax,[di-(sector-entry_size)] ; 获取条目在目录中的指针
                        ; 加上一个条目（文件从磁道 1 开始）
        mov cl,4        ; 2^(8-4) = entry_size
        shl ax,cl       ; 左移并清除进位标志
        inc ax          ; AL = 扇区 1
        xchg ax,cx      ; CH = 磁道，CL = 扇区
        ret

        ;
        ; >> 命令 <<
        ; format
        ;
format_command:
        mov di,sector   ; 将整个扇区填零
        mov cx,sector_size
        call write_zero_dir
        mov bx,osbase   ; 将 bootOS 复制到第一个扇区
        dec cx
        jmp short disk

        ;
        ; 从磁盘读取目录
        ;
read_dir:
        push cs         ; bootOS 代码段...
        pop es          ; ...以清理 ES 寄存器
        mov ah,0x02
        jmp short disk_dir

write_zero_dir:
        mov al,0
        rep stosb

        ;
        ; 将目录写入磁盘
        ;
write_dir:
        mov ah,0x03
disk_dir:
        mov bx,sector
        mov cx,0x0002
        ;
        ; 执行磁盘操作。
        ;
        ; 输入：
        ;   AH = 0x02 读磁盘，0x03 写磁盘
        ;   ES:BX = 数据源/目标
        ;   CH = 磁道号
        ;   CL = 扇区号
        ;
disk:
        push ax
        push bx
        push cx
        push es
        mov al,0x01     ; AL = 1 个扇区
        xor dx,dx       ; DH = 驱动器 A。DL = 磁头 0。
        int 0x13
        pop es
        pop cx
        pop bx
        pop ax
        jc disk         ; 重试
        ret

        ;
        ; 从键盘输入一行
        ; 入口：
        ;   al = 提示符字符
        ; 输出：
        ;   缓冲区 'line' 包含该行，以 CR 结尾
        ;   SI 指向 'line'。
        ;
input_line:
        int int_output_char ; 输出提示符字符
        mov si,line     ; 将 SI 和 DI 设置到行缓冲区起始处
        mov di,si       ; 写入行的目标
os1:    cmp al,0x08     ; 退格键？
        jne os2
        dec di          ; 撤销退格的写入
        dec di          ; 擦除一个字符
os2:    int int_input_key  ; 读取键盘
        cmp al,0x0d     ; 按下 CR 了吗？
        jne os10
        mov al,0x00
os10:   stosb           ; 将按键保存到缓冲区
        jne os1         ; 不是，则等待另一个按键
        ret             ; 是，则返回

        ;
        ; 读取一个按键到 al
        ; 同时把它输出到屏幕
        ;
input_key:
        mov ah,0x00
        int 0x16
        ;
        ; 将 al 中包含的字符输出到屏幕
        ; 把 0x0d (CR) 展开为 0x0a 0x0d (LF CR)
        ;
output_char:
        cmp al,0x0d
        jne os3
        mov al,0x0a
        int int_output_char
        mov al,0x0d
os3:
        mov ah,0x0e     ; 向 TTY 输出字符
        mov bx,0x0007   ; 灰色。图形模式下需要
        int 0x10        ; BIOS int 0x10 = 视频
        iret

        ;
        ; 输出字符串
        ;
        ; 入口：
        ;   SI = 地址
        ;
        ; 实现：
        ;   它假设 SI 永远不会指向长度为零的字符串。
        ;
output_string:
        lodsb                   ; 读取字符
        int int_output_char     ; 输出到屏幕
        cmp al,0x00             ; 是 0x00（结束符）吗？
        jne output_string       ; 不是，则继续循环
        mov al,0x0d
        int int_output_char
        ret

        ;
        ; 'enter' 命令
        ;
enter_command:
        mov di,boot             ; 指向引导扇区
os23:   push di
        mov al,'h'              ; 提示符字符
        call input_line         ; 输入一行
        pop di
        cmp byte [si],0         ; 是空行吗？
        je os20                 ; 是，则跳转
os19:   call xdigit             ; 获取一个十六进制数字
        jnc os23
        mov cl,4
        shl al,cl
        xchg ax,cx
        call xdigit             ; 获取一个十六进制数字
        or al,cl
        stosb                   ; 写入一个字节
        jmp os19                ; 重复循环以完成该行
os20:
        mov al,'*'              ; 提示符字符
        call input_line         ; 输入带文件名的行
        push si
        pop bx
        mov di,boot             ; 指向输入的数据
        int int_save_file       ; 保存新文件
        ret

        ;
        ; 将 ASCII 字母转换为十六进制数字
        ;
xdigit:
        lodsb
        cmp al,0x00             ; 零字符标记行结束
        je os15
        sub al,0x30             ; 跳过空格（任何低于 ASCII 0x30 的字符）
        jc xdigit
        cmp al,0x0a
        jc os15
        sub al,0x07
        and al,0x0f
        stc
os15:
        ret

        ;
        ; 我们了不起的展示行
        ;
intro:
        db "bootOS",0

error_message:
        db "Oops",0

        ;
        ; bootOS 支持的命令
        ;
commands:
        db 3,"dir"
        dw dir_command
        db 6,"format"
        dw format_command
        db 5,"enter"
        dw enter_command
        db 3,"del"
        dw del_command
        db 3,"ver"
        dw ver_command
        db 0
        dw exec_from_disk

int_restart:            equ 0x20
int_input_key:          equ 0x21
int_output_char:        equ 0x22
int_load_file:          equ 0x23
int_save_file:          equ 0x24
int_delete_file:        equ 0x25

int_0x20:
        dw restart          ; int 0x20
        dw input_key        ; int 0x21
        dw output_char      ; int 0x22
        dw load_file        ; int 0x23
        dw save_file        ; int 0x24
        dw delete_file      ; int 0x25

        times 510-($-$$) db 0x4f
        db 0x55,0xaa            ; 使其成为可引导扇区
