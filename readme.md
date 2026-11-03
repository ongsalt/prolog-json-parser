# วิธีรัน
0. โหลด `main.pl`
1. เปิด swi prolog [โหลดจากนี่](https://www.swi-prolog.org/download/stable)
2. ตั้งค่าการ parse string
```prolog
set_prolog_flag(double_quotes, chars)
```
3. กด File -> Consult
4. เลือก `main.pl` อาจมี Warning ขึ้น แต่ช่างมัน
5. ลอง 
```prolog
parse('{ "hihi": "Kroos", "id": 1 }', Out).
```

# Todo
- หาวิธีที่ทำให้ไม่ต้อง `set_prolog_flag`
- ดู DCG
- query language?