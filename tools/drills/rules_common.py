"""How a drill keeps going once the board has run — the 【规则】 line.

The board animates one rep. What happens next — who goes to the back of
the line, when the defenders swap, how a game restarts after a goal — is
what makes a drill runnable for ten minutes rather than once, and it has
no beat to derive it from, so it is written here. One text per way of
continuing, in twelve locales; a sport's table names which drill gets
which. A drill with its own particular rule (the rondo swap) writes its
own and is not listed.
"""

# A line of players and one rep each: dribbles, finishing, first touch,
# crossing, conditioning.
QUEUE_RULES = {
    "en": "Back to the end of the line when your rep is done and the next player goes; six to eight each, then switch sides or roles.",
    "en-GB": "Back to the end of the line when your rep is done and the next player goes; six to eight each, then switch sides or roles.",
    "zh-CN": "做完一次回到队尾，下一人出发；每人 6–8 次后换边或换角色。",
    "zh-TW": "做完一次回到隊尾，下一人出發；每人 6–8 次後換邊或換角色。",
    "ja-JP": "1本終えたら列の最後尾へ戻り、次の選手が出る。1人6〜8本で左右か役割を交代。",
    "ko-KR": "한 번 마치면 줄 맨 뒤로 가고 다음 선수가 출발한다. 한 사람당 6~8회 후 방향이나 역할을 바꾼다.",
    "es-ES": "Al terminar tu repetición vuelves al final de la fila y sale el siguiente; seis a ocho cada uno, luego cambio de lado o de rol.",
    "fr-FR": "Ta répétition finie, tu retournes en fin de file et le suivant part ; six à huit chacun, puis on change de côté ou de rôle.",
    "id-ID": "Selesai satu ulangan kembali ke belakang barisan dan pemain berikutnya berangkat; enam sampai delapan kali tiap orang, lalu ganti sisi atau peran.",
    "ms-MY": "Selesai satu ulangan kembali ke belakang barisan dan pemain seterusnya bermula; enam hingga lapan kali setiap orang, kemudian tukar sisi atau peranan.",
    "th-TH": "ทำเสร็จหนึ่งรอบกลับไปต่อท้ายแถว คนถัดไปออกตัว คนละ 6–8 รอบแล้วสลับข้างหรือสลับหน้าที่",
    "vi-VN": "Xong lượt của mình thì về cuối hàng, người tiếp theo xuất phát; mỗi người 6–8 lượt rồi đổi bên hoặc đổi vai.",
}

# A pattern run by a group: the ball comes back to the start and everyone
# steps round one position, so each man plays every part.
PATTERN_RULES = {
    "en": "When the pattern is done the ball goes back to the start and everyone moves round one position, so each player takes every part; eight runs, then mirror it to the other side.",
    "en-GB": "When the pattern is done the ball goes back to the start and everyone moves round one position, so each player takes every part; eight runs, then mirror it to the other side.",
    "zh-CN": "一次配合完成后球回到起点，所有人顺时针换一个位置，每人轮到每个角色；做 8 次后镜像到另一侧。",
    "zh-TW": "一次配合完成後球回到起點，所有人順時針換一個位置，每人輪到每個角色；做 8 次後鏡像到另一側。",
    "ja-JP": "1回終えたらボールをスタートに戻し、全員が1つずつ位置をずらして全役割を回る。8回やったら逆サイドで鏡写しに。",
    "ko-KR": "한 번 끝나면 공은 출발점으로 돌아가고 모두 한 자리씩 이동해 모든 역할을 거친다. 8회 후 반대쪽으로 거울처럼 바꾼다.",
    "es-ES": "Terminado el patrón, el balón vuelve al inicio y todos rotan una posición, así cada uno pasa por cada papel; ocho veces y luego en espejo hacia el otro lado.",
    "fr-FR": "Le schéma terminé, le ballon revient au départ et chacun avance d'une position pour tenir tous les rôles ; huit passages, puis en miroir de l'autre côté.",
    "id-ID": "Setelah pola selesai bola kembali ke awal dan semua bergeser satu posisi agar tiap pemain mencoba setiap peran; delapan kali, lalu cerminkan ke sisi lain.",
    "ms-MY": "Selepas corak selesai bola kembali ke permulaan dan semua beralih satu posisi supaya setiap pemain mencuba setiap peranan; lapan kali, kemudian cerminkan ke sisi lain.",
    "th-TH": "จบหนึ่งแพตเทิร์นบอลกลับไปจุดเริ่ม ทุกคนขยับไปหนึ่งตำแหน่งเพื่อให้ได้เล่นทุกบทบาท ทำ 8 รอบแล้วสลับไปอีกฝั่งแบบกระจก",
    "vi-VN": "Xong một bài phối hợp, bóng về điểm xuất phát và mọi người dịch một vị trí để ai cũng qua từng vai; làm 8 lần rồi đổi sang bên kia theo kiểu đối xứng.",
}

# A rep against live defenders: attackers queue, defenders hold.
DUEL_RULES = {
    "en": "A rep ends on a shot, a tackle or the ball going out. The attackers rejoin the queue and the next go straight in; the defenders hold for four reps, then swap with the attackers.",
    "en-GB": "A rep ends on a shot, a tackle or the ball going out. The attackers rejoin the queue and the next go straight in; the defenders hold for four reps, then swap with the attackers.",
    "zh-CN": "一球结束——射门、断球或球出界——进攻方回到队尾，下一组马上进攻；防守方连守四球后与进攻互换。",
    "zh-TW": "一球結束——射門、斷球或球出界——進攻方回到隊尾，下一組馬上進攻；防守方連守四球後與進攻互換。",
    "ja-JP": "シュート、ボール奪取、ボールアウトで1本終了。攻撃側は列に戻り次の組がすぐ入る。守備側は4本続けてから攻守交代。",
    "ko-KR": "슈팅, 태클, 아웃으로 한 세트가 끝난다. 공격은 줄로 돌아가고 다음 조가 바로 들어온다. 수비는 네 번을 막은 뒤 공격과 교대한다.",
    "es-ES": "La repetición termina con un tiro, un robo o el balón fuera. Los atacantes vuelven a la fila y entran los siguientes; los defensores aguantan cuatro y luego cambian con los atacantes.",
    "fr-FR": "La séquence s'arrête sur un tir, une récupération ou une sortie de balle. Les attaquants rejoignent la file et les suivants enchaînent ; les défenseurs tiennent quatre séquences puis permutent.",
    "id-ID": "Satu ulangan berakhir dengan tembakan, rebutan, atau bola keluar. Penyerang kembali ke antrean dan yang berikutnya langsung masuk; bek bertahan empat ulangan lalu bertukar dengan penyerang.",
    "ms-MY": "Satu ulangan tamat dengan rembatan, rampasan, atau bola keluar. Penyerang kembali ke barisan dan yang seterusnya terus masuk; pemain bertahan kekal empat ulangan kemudian bertukar dengan penyerang.",
    "th-TH": "จบหนึ่งรอบเมื่อยิง แย่งบอลได้ หรือบอลออก ฝ่ายบุกกลับไปต่อแถวแล้วชุดถัดไปเข้าทันที ฝ่ายรับรับสี่รอบแล้วสลับกับฝ่ายบุก",
    "vi-VN": "Một lượt kết thúc khi có cú sút, cướp được bóng hoặc bóng ra ngoài. Bên tấn công về xếp hàng, cặp tiếp theo vào ngay; bên phòng ngự giữ bốn lượt rồi đổi vai.",
}

# A game on a coned pitch with mini-goals: it restarts itself, and there is
# no keeper to restart from.
GAME_RULES = {
    "en": "After a goal the team that conceded restarts from its own end line; when the ball goes out the other team brings it in from where it left, and the coach has spares ready so nothing stops. Four-minute games, then swap ends or opponents.",
    "en-GB": "After a goal the team that conceded restarts from its own end line; when the ball goes out the other team brings it in from where it left, and the coach has spares ready so nothing stops. Four-minute games, then swap ends or opponents.",
    "zh-CN": "进球后由失球方从本方端线开球；球出界由对方在出界处发球，教练备好几个球随时补上，比赛不停。每局 4 分钟，局间换边或换对手。",
    "zh-TW": "進球後由失球方從本方端線開球；球出界由對方在出界處發球，教練備好幾個球隨時補上，比賽不停。每局 4 分鐘，局間換邊或換對手。",
    "ja-JP": "得点後は失点した側が自陣エンドラインから再開。ボールが出たら相手が出た地点から入れ、コーチが予備球をすぐ入れて止めない。1ゲーム4分で、エンドか相手を交代。",
    "ko-KR": "골이 들어가면 실점한 팀이 자기 엔드라인에서 재개하고, 공이 나가면 상대가 나간 지점에서 넣는다. 코치가 여분의 공을 바로 넣어 멈추지 않는다. 한 게임 4분 후 진영이나 상대를 바꾼다.",
    "es-ES": "Tras un gol reanuda el equipo que lo encajó desde su línea de fondo; si la bola sale, la mete el rival desde donde salió, y el entrenador tiene balones listos para que no se pare. Partidos de cuatro minutos y cambio de campo o de rival.",
    "fr-FR": "Après un but, l'équipe encaissée relance de sa ligne de fond ; ballon sorti, l'adversaire le remet là où il est sorti, et l'entraîneur a des ballons prêts pour que rien ne s'arrête. Matchs de quatre minutes, puis on change de côté ou d'adversaire.",
    "id-ID": "Setelah gol, tim yang kebobolan memulai dari garis akhirnya; bila bola keluar, lawan memasukkannya dari tempat bola keluar, dan pelatih menyiapkan bola cadangan agar tidak berhenti. Gim empat menit, lalu tukar sisi atau lawan.",
    "ms-MY": "Selepas gol, pasukan yang kemasukan memulakan dari garisan hujungnya; jika bola keluar, lawan memasukkannya dari tempat ia keluar, dan jurulatih menyediakan bola ganti supaya tiada yang terhenti. Perlawanan empat minit, kemudian tukar sisi atau lawan.",
    "th-TH": "หลังเสียประตู ฝ่ายที่เสียเริ่มจากเส้นหลังของตัวเอง บอลออกให้ฝ่ายตรงข้ามนำเข้าเล่นตรงจุดที่ออก โค้ชเตรียมบอลสำรองไว้เพื่อไม่ให้เกมหยุด เกมละ 4 นาที แล้วสลับแดนหรือคู่แข่ง",
    "vi-VN": "Sau bàn thua, đội thủng lưới phát bóng từ vạch cuối sân của mình; bóng ra ngoài thì đội kia ném vào ngay chỗ bóng ra, huấn luyện viên có bóng dự phòng để không bị gián đoạn. Mỗi trận bốn phút rồi đổi sân hoặc đổi đối thủ.",
}

# A possession grid with no goals: the ball goes out, the coach serves a
# new one, and nothing stops.
GRID_RULES = {
    "en": "When the ball leaves the grid the coach serves a new one to the team that did not put it out, and play carries on; six minutes, then the defenders swap with two of the players who have been keeping it.",
    "en-GB": "When the ball leaves the grid the coach serves a new one to the team that did not put it out, and play carries on; six minutes, then the defenders swap with two of the players who have been keeping it.",
    "zh-CN": "球出区后由教练把新球发给不是把球弄出去的一方，练习不停；做 6 分钟后，两名防守者与控球方的两人互换。",
    "zh-TW": "球出區後由教練把新球發給不是把球弄出去的一方，練習不停；做 6 分鐘後，兩名防守者與控球方的兩人互換。",
    "ja-JP": "ボールがグリッドを出たら、出した側でない方にコーチが新しいボールを入れて続行。6分やったら守備の2人と保持側の2人を交代。",
    "ko-KR": "공이 그리드를 벗어나면 공을 내보내지 않은 팀에게 코치가 새 공을 넣어 주고 계속한다. 6분 후 수비 두 명과 소유 팀의 두 명을 교대한다.",
    "es-ES": "Cuando el balón sale de la cuadrícula, el entrenador mete otro al equipo que no lo sacó y se sigue jugando; seis minutos y los defensores cambian con dos de los que conservaban.",
    "fr-FR": "Quand le ballon sort de la grille, l'entraîneur en remet un à l'équipe qui ne l'a pas sorti et on continue ; six minutes, puis les deux défenseurs permutent avec deux joueurs de la conservation.",
    "id-ID": "Saat bola keluar grid, pelatih memasukkan bola baru untuk tim yang tidak mengeluarkannya dan permainan berlanjut; enam menit, lalu dua bek bertukar dengan dua pemain penguasa bola.",
    "ms-MY": "Apabila bola keluar grid, jurulatih memasukkan bola baharu kepada pasukan yang tidak mengeluarkannya dan permainan diteruskan; enam minit, kemudian dua pemain bertahan bertukar dengan dua pemain penguasa bola.",
    "th-TH": "เมื่อบอลออกนอกกริด โค้ชเติมบอลใหม่ให้ฝ่ายที่ไม่ได้ทำออก แล้วเล่นต่อ ทำ 6 นาทีแล้วสลับฝ่ายรับสองคนกับฝ่ายครองบอลสองคน",
    "vi-VN": "Khi bóng ra khỏi ô, huấn luyện viên đưa bóng mới cho đội không làm bóng ra và tiếp tục; sáu phút rồi hai người phòng ngự đổi với hai người giữ bóng.",
}

# Build-up against a press, and the press itself: one side succeeds or
# the other does, and the ball goes back to the keeper either way.
BUILDUP_RULES = {
    "en": "Getting the ball over halfway counts as a success; a turnover or the ball out counts for the pressers. Either way it goes back to the keeper and starts again; six reps, then the sides swap.",
    "en-GB": "Getting the ball over halfway counts as a success; a turnover or the ball out counts for the pressers. Either way it goes back to the keeper and starts again; six reps, then the sides swap.",
    "zh-CN": "球过中线算出球成功，被断或出界算压迫方得分；无论哪种，球回门将重新开始，连做 6 次后攻守互换。",
    "zh-TW": "球過中線算出球成功，被斷或出界算壓迫方得分；無論哪種，球回門將重新開始，連做 6 次後攻守互換。",
    "ja-JP": "ハーフウェーを越えれば成功、奪われるかアウトならプレス側の得点。どちらでもキーパーに戻して再開。6本で攻守交代。",
    "ko-KR": "하프라인을 넘기면 성공, 빼앗기거나 아웃되면 압박하는 쪽의 득점이다. 어느 쪽이든 공은 골키퍼에게 돌아가 다시 시작한다. 6회 후 공수 교대.",
    "es-ES": "Superar el medio campo es un éxito; una pérdida o el balón fuera puntúa para los presionadores. En ambos casos vuelve al portero y se reinicia; seis repeticiones y cambio de roles.",
    "fr-FR": "Passer la ligne médiane, c'est réussi ; une perte ou une sortie, c'est un point pour le pressing. Dans les deux cas retour au gardien et on repart ; six fois, puis on inverse les rôles.",
    "id-ID": "Bola melewati garis tengah berarti berhasil; bola direbut atau keluar berarti poin untuk penekan. Apa pun hasilnya bola kembali ke kiper dan mulai lagi; enam ulangan, lalu tukar peran.",
    "ms-MY": "Bola melepasi garisan tengah dikira berjaya; bola dirampas atau keluar dikira mata untuk penekan. Apa pun bola kembali kepada penjaga gol dan mula semula; enam ulangan, kemudian tukar peranan.",
    "th-TH": "บอลข้ามเส้นกลางสนามนับว่าสำเร็จ ถ้าโดนแย่งหรือบอลออกฝ่ายเพรสได้แต้ม ไม่ว่าแบบไหนบอลกลับไปที่ผู้รักษาประตูแล้วเริ่มใหม่ ทำ 6 รอบแล้วสลับฝ่าย",
    "vi-VN": "Đưa bóng qua giữa sân là thành công; mất bóng hoặc bóng ra ngoài tính điểm cho bên pressing. Dù thế nào bóng cũng về thủ môn và bắt đầu lại; 6 lượt rồi đổi bên.",
}

# A dead ball: everyone resets, the next taker steps up.
SETPIECE_RULES = {
    "en": "After each delivery everyone resets to the starting positions and the next taker steps up; eight in a row, half from the left and half from the right.",
    "en-GB": "After each delivery everyone resets to the starting positions and the next taker steps up; eight in a row, half from the left and half from the right.",
    "zh-CN": "每罚一次，所有人回到起始站位，换下一名主罚；连续 8 次，一半从左边一半从右边。",
    "zh-TW": "每罰一次，所有人回到起始站位，換下一名主罰；連續 8 次，一半從左邊一半從右邊。",
    "ja-JP": "1本蹴るごとに全員がスタート位置に戻り、次のキッカーに交代。8本続けて、半分は左から半分は右から。",
    "ko-KR": "한 번 찰 때마다 모두 처음 위치로 돌아가고 다음 키커가 나선다. 연속 8회, 절반은 왼쪽에서 절반은 오른쪽에서.",
    "es-ES": "Tras cada saque todos vuelven a la posición inicial y lanza el siguiente; ocho seguidos, la mitad desde la izquierda y la mitad desde la derecha.",
    "fr-FR": "Après chaque frappe tout le monde se replace au départ et le tireur suivant s'avance ; huit d'affilée, moitié de gauche, moitié de droite.",
    "id-ID": "Setelah tiap eksekusi semua kembali ke posisi awal dan pengeksekusi berikutnya maju; delapan berturut-turut, separuh dari kiri dan separuh dari kanan.",
    "ms-MY": "Selepas setiap sepakan semua kembali ke posisi permulaan dan penyepak seterusnya maju; lapan berturut-turut, separuh dari kiri dan separuh dari kanan.",
    "th-TH": "หลังเตะแต่ละครั้งทุกคนกลับไปตำแหน่งเริ่มต้นและเปลี่ยนคนเตะคนถัดไป ทำติดกัน 8 ครั้ง ครึ่งหนึ่งจากฝั่งซ้าย ครึ่งหนึ่งจากฝั่งขวา",
    "vi-VN": "Sau mỗi quả đá, mọi người về vị trí ban đầu và người đá tiếp theo bước lên; 8 quả liên tiếp, một nửa từ bên trái, một nửa từ bên phải.",
}

# Keeper work: the keeper resets, the servers take turns.
GK_RULES = {
    "en": "After each ball the keeper resets on the line and the next server goes; ten balls a set, then the keepers swap.",
    "en-GB": "After each ball the keeper resets on the line and the next server goes; ten balls a set, then the keepers swap.",
    "zh-CN": "每一球处理完，门将回到门线预备，下一名喂球者接着喂；10 球一组，换门将。",
    "zh-TW": "每一球處理完，門將回到門線預備，下一名餵球者接著餵；10 球一組，換門將。",
    "ja-JP": "1球処理するごとにキーパーはラインに戻って構え、次のサーバーが出す。10球1セットでキーパー交代。",
    "ko-KR": "한 공을 처리할 때마다 골키퍼는 라인으로 돌아가 준비하고 다음 서버가 공을 준다. 10개 한 세트, 골키퍼 교대.",
    "es-ES": "Tras cada balón el portero se recoloca en la línea y sirve el siguiente; series de diez balones, luego cambio de portero.",
    "fr-FR": "Après chaque ballon le gardien se replace sur sa ligne et le serveur suivant enchaîne ; séries de dix ballons, puis on change de gardien.",
    "id-ID": "Setelah tiap bola kiper bersiap lagi di garis dan pengumpan berikutnya giliran; sepuluh bola per set, lalu kiper bertukar.",
    "ms-MY": "Selepas setiap bola penjaga gol bersedia semula di garisan dan pengumpan seterusnya bermula; sepuluh bola satu set, kemudian penjaga gol bertukar.",
    "th-TH": "หลังจัดการแต่ละลูก ผู้รักษาประตูกลับไปตั้งท่าที่เส้นแล้วคนป้อนคนถัดไปป้อน ชุดละ 10 ลูกแล้วเปลี่ยนผู้รักษาประตู",
    "vi-VN": "Sau mỗi bóng thủ môn về lại vạch cầu môn chuẩn bị, người tiếp theo phát bóng; mỗi hiệp 10 bóng rồi đổi thủ môn.",
}

# Pass and follow: the shape rotates on its own.
ROTATION_RULES = {
    "en": "Pass and follow: after your pass, run to the position you passed to and join the back of that line, so the shape rotates by itself; two minutes one way, then reverse the direction.",
    "en-GB": "Pass and follow: after your pass, run to the position you passed to and join the back of that line, so the shape rotates by itself; two minutes one way, then reverse the direction.",
    "zh-CN": "传完跟着球跑：传给谁就跑到谁的位置排到队尾，队形自动轮转不停；一个方向转 2 分钟后反方向。",
    "zh-TW": "傳完跟著球跑：傳給誰就跑到誰的位置排到隊尾，隊形自動輪轉不停；一個方向轉 2 分鐘後反方向。",
    "ja-JP": "パス＆フォロー：出したら出した先の列の最後尾へ走り、形が自動で回る。2分回したら逆回り。",
    "ko-KR": "패스 앤 팔로우: 패스한 뒤 받은 사람의 자리 줄 맨 뒤로 달려가 대형이 저절로 돈다. 한 방향 2분 후 반대 방향.",
    "es-ES": "Pasa y sigue: tras tu pase corres a la posición a la que pasaste y te pones al final de esa fila, así la figura rota sola; dos minutos en un sentido y luego al contrario.",
    "fr-FR": "Passe et suit : après ta passe tu cours vers la position que tu as servie et tu te mets en fin de file, la figure tourne toute seule ; deux minutes dans un sens, puis on inverse.",
    "id-ID": "Umpan lalu ikuti: setelah mengumpan lari ke posisi yang kamu umpan dan masuk ke belakang barisannya, jadi formasi berputar sendiri; dua menit satu arah, lalu balik arah.",
    "ms-MY": "Hantar lalu ikut: selepas menghantar, lari ke posisi yang kamu hantar dan masuk ke belakang barisannya, jadi bentuk berputar sendiri; dua minit satu arah, kemudian terbalikkan arah.",
    "th-TH": "ส่งแล้วตาม: ส่งให้ใครก็วิ่งไปต่อท้ายแถวตำแหน่งนั้น รูปแบบจะหมุนไปเอง หมุนทางเดียว 2 นาทีแล้วกลับทิศ",
    "vi-VN": "Chuyền rồi chạy theo: chuyền cho ai thì chạy đến vị trí đó và xếp cuối hàng, đội hình tự xoay; hai phút một chiều rồi đổi chiều.",
}

# Two balls in one shape: they must never meet.
TWO_BALL_RULES = {
    "en": "Both balls keep moving; if they meet on one player or one goes out, stop, put both back at their starting corners and go again. One minute, then reverse the direction.",
    "en-GB": "Both balls keep moving; if they meet on one player or one goes out, stop, put both back at their starting corners and go again. One minute, then reverse the direction.",
    "zh-CN": "两个球同时转不停；两球撞到同一个人或有球出界，就停下来放回起始的两个角重新开始。1 分钟后换方向。",
    "zh-TW": "兩個球同時轉不停；兩球撞到同一個人或有球出界，就停下來放回起始的兩個角重新開始。1 分鐘後換方向。",
    "ja-JP": "2つのボールを止めずに回す。同じ選手に2つ集まるか外に出たら止めて、スタートの2隅に戻してやり直す。1分で逆回り。",
    "ko-KR": "두 공을 멈추지 않고 돌린다. 한 선수에게 두 공이 모이거나 공이 나가면 멈추고 출발 코너 두 곳에 다시 놓고 시작한다. 1분 후 방향을 바꾼다.",
    "es-ES": "Los dos balones no paran; si coinciden en un jugador o uno sale, se para, se colocan en sus esquinas de inicio y se vuelve a empezar. Un minuto y cambio de sentido.",
    "fr-FR": "Les deux ballons tournent sans arrêt ; s'ils arrivent sur le même joueur ou qu'un sort, on stoppe, on les replace aux deux coins de départ et on repart. Une minute, puis on inverse.",
    "id-ID": "Kedua bola terus bergerak; jika bertemu pada satu pemain atau satu keluar, berhenti, taruh kembali di sudut awalnya dan mulai lagi. Satu menit, lalu balik arah.",
    "ms-MY": "Kedua-dua bola terus bergerak; jika bertemu pada seorang pemain atau satu keluar, berhenti, letak semula di sudut permulaan dan mula semula. Satu minit, kemudian terbalikkan arah.",
    "th-TH": "บอลสองลูกหมุนไม่หยุด ถ้ามาชนกันที่คนเดียวหรือลูกใดออก ให้หยุด วางกลับที่มุมเริ่มต้นทั้งสองแล้วเริ่มใหม่ 1 นาทีแล้วกลับทิศ",
    "vi-VN": "Hai bóng luân chuyển liên tục; nếu dồn vào một người hoặc một quả ra ngoài thì dừng, đặt lại hai góc xuất phát và làm lại. Một phút rồi đổi chiều.",
}

# ── net and racket sports ────────────────────────────────────────────────
# A feeder and a worker: the feed never stops.
FEED_RULES = {
    "en": "The feeder keeps the balls coming, one after another, without waiting for the last one to be played out; a set is 15–20 balls, then the worker and the feeder swap.",
    "en-GB": "The feeder keeps the balls coming, one after another, without waiting for the last one to be played out; a set is 15–20 balls, then the worker and the feeder swap.",
    "zh-CN": "喂球者一球接一球连续喂，不等上一球落地；一组 15–20 球，练习者和喂球者互换。",
    "zh-TW": "餵球者一球接一球連續餵，不等上一球落地；一組 15–20 球，練習者和餵球者互換。",
    "ja-JP": "フィーダーは前の球を待たずに次々と出す。1セット15〜20球で、打つ側と出す側を交代。",
    "ko-KR": "피더는 앞 공이 끝나길 기다리지 않고 연속으로 공을 준다. 한 세트 15~20개, 그 후 치는 사람과 주는 사람이 교대한다.",
    "es-ES": "El alimentador saca bola tras bola sin esperar a que se juegue la anterior; una serie son 15–20 bolas y luego cambian de papel.",
    "fr-FR": "Le distributeur enchaîne les balles sans attendre la fin de l'échange précédent ; une série fait 15–20 balles, puis on inverse les rôles.",
    "id-ID": "Pengumpan terus memberi bola satu demi satu tanpa menunggu bola sebelumnya selesai; satu set 15–20 bola, lalu pemain dan pengumpan bertukar.",
    "ms-MY": "Pengumpan terus memberi bola satu demi satu tanpa menunggu bola sebelumnya selesai; satu set 15–20 bola, kemudian pemain dan pengumpan bertukar.",
    "th-TH": "คนป้อนป้อนลูกต่อเนื่องไม่รอลูกก่อนหน้า ชุดละ 15–20 ลูก แล้วสลับคนตีกับคนป้อน",
    "vi-VN": "Người phát bóng đưa bóng liên tục, không đợi bóng trước kết thúc; mỗi hiệp 15–20 bóng rồi người tập và người phát đổi vai.",
}

# Two players trading a fixed shot: the rally is the rep.
RALLY_RULES = {
    "en": "Play the rally until it breaks down, then the same player starts the next one straight away; after ten rallies swap ends and, where the shots differ, roles.",
    "en-GB": "Play the rally until it breaks down, then the same player starts the next one straight away; after ten rallies swap ends and, where the shots differ, roles.",
    "zh-CN": "一个回合打到失误为止，由同一人立刻开始下一回合；打 10 个回合后换边，两人击球不同的就换角色。",
    "zh-TW": "一個回合打到失誤為止，由同一人立刻開始下一回合；打 10 個回合後換邊，兩人擊球不同的就換角色。",
    "ja-JP": "ラリーが途切れるまで続け、同じ人がすぐ次を始める。10ラリーでコートを替え、役割が違う場合は役割も替える。",
    "ko-KR": "랠리가 끊길 때까지 치고, 같은 사람이 바로 다음을 시작한다. 열 번 후 코트를 바꾸고, 역할이 다르면 역할도 바꾼다.",
    "es-ES": "Se pelotea hasta que se rompe el intercambio y el mismo jugador inicia el siguiente de inmediato; tras diez intercambios cambio de lado y, si los golpes son distintos, de papel.",
    "fr-FR": "L'échange se joue jusqu'à la faute, puis le même joueur relance aussitôt ; après dix échanges on change de côté et, si les coups diffèrent, de rôle.",
    "id-ID": "Reli dimainkan sampai putus, lalu pemain yang sama langsung memulai lagi; setelah sepuluh reli tukar sisi dan, bila pukulannya berbeda, tukar peran.",
    "ms-MY": "Rali dimainkan sehingga terputus, kemudian pemain yang sama terus memulakan semula; selepas sepuluh rali tukar sisi dan, jika pukulan berbeza, tukar peranan.",
    "th-TH": "ตีโต้จนกว่าจะเสีย แล้วคนเดิมเริ่มรอบถัดไปทันที ครบ 10 รอบสลับฝั่ง ถ้าลูกที่ตีต่างกันก็สลับหน้าที่ด้วย",
    "vi-VN": "Đánh qua lại đến khi hỏng, người đó bắt đầu ngay lượt tiếp; sau mười lượt đổi sân và, nếu cú đánh khác nhau, đổi vai.",
}

# Points played out under a condition.
POINT_RULES = {
    "en": "Play each point out and keep score; serve alternates every two points. Games to 11, then swap ends, and swap partners or opponents.",
    "en-GB": "Play each point out and keep score; serve alternates every two points. Games to 11, then swap ends, and swap partners or opponents.",
    "zh-CN": "每一分打到底并计分，每两分换发球；打到 11 分一局，局间换边、换搭档或换对手。",
    "zh-TW": "每一分打到底並計分，每兩分換發球；打到 11 分一局，局間換邊、換搭檔或換對手。",
    "ja-JP": "1ポイントずつ最後まで打って得点を数え、2ポイントごとにサーブ交代。11点で1ゲーム、コート・パートナー・相手を替える。",
    "ko-KR": "한 점씩 끝까지 치며 점수를 세고, 두 점마다 서브를 바꾼다. 11점 한 게임, 그 후 코트와 파트너 또는 상대를 바꾼다.",
    "es-ES": "Cada punto se juega hasta el final y se cuenta; el saque cambia cada dos puntos. Juegos a 11, luego cambio de lado y de pareja o rival.",
    "fr-FR": "Chaque point se joue jusqu'au bout et compte ; le service change tous les deux points. Jeux en 11, puis on change de côté et de partenaire ou d'adversaire.",
    "id-ID": "Setiap poin dimainkan sampai selesai dan dihitung; servis bergantian tiap dua poin. Gim sampai 11, lalu tukar sisi dan tukar pasangan atau lawan.",
    "ms-MY": "Setiap mata dimainkan sehingga selesai dan dikira; servis bertukar setiap dua mata. Perlawanan hingga 11, kemudian tukar sisi dan tukar pasangan atau lawan.",
    "th-TH": "เล่นแต่ละแต้มจนจบและนับคะแนน สลับเสิร์ฟทุกสองแต้ม เกมละ 11 แต้ม แล้วสลับฝั่ง สลับคู่หรือคู่แข่ง",
    "vi-VN": "Đánh hết từng điểm và tính điểm; đổi giao bóng sau mỗi hai điểm. Ván đến 11, rồi đổi sân, đổi cặp hoặc đổi đối thủ.",
}

# Serve and return practice.
SERVE_RULES = {
    "en": "Ten serves, then the server and the receiver swap; the returner plays every ball as if the rally were live, and the server collects the balls between sets.",
    "en-GB": "Ten serves, then the server and the receiver swap; the returner plays every ball as if the rally were live, and the server collects the balls between sets.",
    "zh-CN": "连发 10 个球后发球者与接发者互换；接发者每一球都当真回合来打，发球者在组间捡球。",
    "zh-TW": "連發 10 個球後發球者與接發者互換；接發者每一球都當真回合來打，發球者在組間撿球。",
    "ja-JP": "10本サーブしたらサーバーとレシーバーを交代。レシーバーは毎球本番のように返し、サーバーはセット間に球を集める。",
    "ko-KR": "서브 열 개 후 서버와 리시버가 교대한다. 리시버는 모든 공을 실전처럼 받고, 서버는 세트 사이에 공을 줍는다.",
    "es-ES": "Diez saques y cambio entre sacador y restador; el restador juega cada bola como si el punto fuera real y el sacador recoge las bolas entre series.",
    "fr-FR": "Dix services puis serveur et relanceur permutent ; le relanceur joue chaque balle comme un vrai échange et le serveur ramasse entre les séries.",
    "id-ID": "Sepuluh servis, lalu pengservis dan penerima bertukar; penerima memainkan tiap bola seperti reli sungguhan, pengservis mengumpulkan bola di antara set.",
    "ms-MY": "Sepuluh servis, kemudian penservis dan penerima bertukar; penerima memainkan setiap bola seperti rali sebenar, penservis mengutip bola antara set.",
    "th-TH": "เสิร์ฟ 10 ลูกแล้วสลับคนเสิร์ฟกับคนรับ คนรับตีทุกลูกเหมือนแต้มจริง คนเสิร์ฟเก็บลูกระหว่างชุด",
    "vi-VN": "Mười quả giao bóng rồi người giao và người đỡ đổi vai; người đỡ đánh mọi quả như đang thi đấu, người giao nhặt bóng giữa các hiệp.",
}

# ── bat and ball ─────────────────────────────────────────────────────────
BASEBALL_RULES = {
    "en": "After each ball everyone resets to the starting positions and the next ball goes in; ten reps, then the fielders rotate one position round and the runners or hitters swap with the next group.",
    "en-GB": "After each ball everyone resets to the starting positions and the next ball goes in; ten reps, then the fielders rotate one position round and the runners or hitters swap with the next group.",
    "zh-CN": "每一球结束后所有人回到起始位置，接着下一球；做 10 次后守备位置顺时针轮换一个，跑垒员或击球员换下一组。",
    "zh-TW": "每一球結束後所有人回到起始位置，接著下一球；做 10 次後守備位置順時針輪換一個，跑壘員或擊球員換下一組。",
    "ja-JP": "1球ごとに全員がスタート位置に戻り次の球へ。10本で守備位置を1つずつ回し、走者や打者は次の組と交代。",
    "ko-KR": "한 공이 끝나면 모두 처음 위치로 돌아가 다음 공으로 간다. 10회 후 수비 위치를 한 자리씩 돌리고 주자나 타자는 다음 조와 교대한다.",
    "es-ES": "Tras cada bola todos vuelven a la posición inicial y entra la siguiente; diez repeticiones y los fildeadores rotan una posición, corredores o bateadores cambian con el siguiente grupo.",
    "fr-FR": "Après chaque balle tout le monde se replace et la suivante part ; dix répétitions, puis les défenseurs tournent d'un poste et coureurs ou frappeurs laissent la place au groupe suivant.",
    "id-ID": "Setelah tiap bola semua kembali ke posisi awal dan bola berikutnya masuk; sepuluh ulangan, lalu penjaga berputar satu posisi dan pelari atau pemukul bertukar dengan kelompok berikutnya.",
    "ms-MY": "Selepas setiap bola semua kembali ke posisi permulaan dan bola seterusnya masuk; sepuluh ulangan, kemudian pemadang berputar satu posisi dan pelari atau pemukul bertukar dengan kumpulan seterusnya.",
    "th-TH": "หลังแต่ละลูกทุกคนกลับตำแหน่งเริ่มต้นแล้วลูกถัดไปเข้า ทำ 10 รอบแล้วผู้เล่นรับหมุนตำแหน่งหนึ่งตำแหน่ง คนวิ่งหรือคนตีสลับกับกลุ่มถัดไป",
    "vi-VN": "Sau mỗi bóng mọi người về vị trí xuất phát và bóng tiếp theo vào; 10 lượt rồi hàng thủ xoay một vị trí, người chạy hoặc người đánh đổi với nhóm kế.",
}

# ── team sports with a queue at the top ─────────────────────────────────
# A half-court or set-play rep: attack, then the next group.
SETPLAY_RULES = {
    "en": "The rep ends on a score, a stop or a turnover; the attacking group jogs off and the next group runs the same play, and the defenders hold for five reps before swapping.",
    "en-GB": "The rep ends on a score, a stop or a turnover; the attacking group jogs off and the next group runs the same play, and the defenders hold for five reps before swapping.",
    "zh-CN": "一次进攻以得分、被封或失误结束；进攻组退出，下一组接着跑同一套配合，防守组守 5 次后与进攻互换。",
    "zh-TW": "一次進攻以得分、被封或失誤結束；進攻組退出，下一組接著跑同一套配合，防守組守 5 次後與進攻互換。",
    "ja-JP": "得点・阻止・ターンオーバーで1本終了。攻撃組は下がり次の組が同じプレーを走る。守備組は5本守ってから攻守交代。",
    "ko-KR": "득점, 저지, 턴오버로 한 번이 끝난다. 공격조는 빠지고 다음 조가 같은 플레이를 하며, 수비조는 다섯 번 막은 뒤 교대한다.",
    "es-ES": "La repetición termina con canasta o gol, parada o pérdida; el grupo atacante sale y el siguiente corre la misma jugada, y la defensa aguanta cinco repeticiones antes de cambiar.",
    "fr-FR": "La séquence se termine sur un point, un arrêt ou une perte ; le groupe attaquant sort, le suivant joue la même combinaison, et la défense tient cinq séquences avant de permuter.",
    "id-ID": "Satu ulangan berakhir dengan skor, dihentikan, atau turnover; kelompok penyerang keluar dan kelompok berikutnya menjalankan pola yang sama, bek bertahan lima ulangan lalu bertukar.",
    "ms-MY": "Satu ulangan tamat dengan skor, dihalang, atau turnover; kumpulan penyerang keluar dan kumpulan seterusnya menjalankan corak yang sama, pemain bertahan kekal lima ulangan kemudian bertukar.",
    "th-TH": "จบหนึ่งรอบเมื่อได้แต้ม ถูกหยุด หรือเสียบอล กลุ่มบุกออกแล้วกลุ่มถัดไปเล่นแบบเดิม ฝ่ายรับรับ 5 รอบแล้วสลับ",
    "vi-VN": "Một lượt kết thúc khi ghi điểm, bị chặn hoặc mất bóng; nhóm tấn công rút ra và nhóm tiếp theo chạy cùng bài, hàng thủ giữ năm lượt rồi đổi vai.",
}

# Volleyball and its cousins: the ball is served in and the play runs.
SERVE_IN_RULES = {
    "en": "Every rep starts with a serve or a toss from the far side; the rally runs to the floor, the same server puts the next ball in, and after six balls the two sides rotate one position.",
    "en-GB": "Every rep starts with a serve or a toss from the far side; the rally runs to the floor, the same server puts the next ball in, and after six balls the two sides rotate one position.",
    "zh-CN": "每一球由对面发球或抛球开始，打到落地为止，同一人接着发下一球；6 球后两边各轮转一个位置。",
    "zh-TW": "每一球由對面發球或拋球開始，打到落地為止，同一人接著發下一球；6 球後兩邊各輪轉一個位置。",
    "ja-JP": "毎回、向こう側のサーブかトスで始め、ボールが落ちるまで続ける。同じ人が次を入れ、6球で両側とも1つローテーション。",
    "ko-KR": "매번 건너편의 서브나 토스로 시작해 공이 떨어질 때까지 이어간다. 같은 사람이 다음 공을 넣고, 여섯 개 후 양쪽 모두 한 자리씩 로테이션한다.",
    "es-ES": "Cada repetición empieza con un saque o un lanzamiento desde el otro lado y se juega hasta que la bola cae; el mismo sacador mete la siguiente y, tras seis, ambos lados rotan una posición.",
    "fr-FR": "Chaque séquence part d'un service ou d'un lancer de l'autre côté et se joue jusqu'au sol ; le même serveur relance la suivante et, après six balles, les deux côtés tournent d'une position.",
    "id-ID": "Setiap ulangan dimulai dengan servis atau lemparan dari seberang, dimainkan sampai bola jatuh; pengservis yang sama memasukkan bola berikutnya, dan setelah enam bola kedua sisi berputar satu posisi.",
    "ms-MY": "Setiap ulangan bermula dengan servis atau lontaran dari seberang, dimainkan sehingga bola jatuh; penservis yang sama memasukkan bola seterusnya, dan selepas enam bola kedua-dua sisi berputar satu posisi.",
    "th-TH": "แต่ละรอบเริ่มด้วยการเสิร์ฟหรือโยนจากอีกฝั่ง เล่นจนบอลตกพื้น คนเดิมเสิร์ฟลูกถัดไป ครบ 6 ลูกทั้งสองฝั่งหมุนหนึ่งตำแหน่ง",
    "vi-VN": "Mỗi lượt bắt đầu bằng giao bóng hoặc tung bóng từ sân bên kia, đánh đến khi bóng chạm đất; cùng người đó giao tiếp, sau sáu bóng cả hai bên xoay một vị trí.",
}

# ══ what a goal is, and what out is ══════════════════════════════════════
# A continuation line that says "after a goal" and a coaching point that
# says "score" both assume the reader knows the rule being played. In a
# drill that is not a match, he does not: a mini-goal, a zone, a line to
# beat and a full goal are four different things.
SCORE_BASKET = {
    "en": "A basket counts two, or three from behind the arc; the defence scores by a stop, a rebound or a steal. The ball is out at the sideline and the other team brings it in from there.",
    "en-GB": "A basket counts two, or three from behind the arc; the defence scores by a stop, a rebound or a steal. The ball is out at the sideline and the other team brings it in from there.",
    "zh-CN": "投中算 2 分，三分线外算 3 分；防守方封盖、抢下篮板或断球算一次防守成功。球出边线由对方在出界处发球。",
    "zh-TW": "投中算 2 分，三分線外算 3 分；防守方封蓋、搶下籃板或斷球算一次防守成功。球出邊線由對方在出界處發球。",
    "ja-JP": "シュート成功は2点、アーク外なら3点。守備は阻止・リバウンド・スティールで成功。ボールがサイドラインを出たら相手がその地点からスローイン。",
    "ko-KR": "득점은 2점, 아크 밖에서는 3점. 수비는 저지·리바운드·스틸로 성공한다. 공이 사이드라인을 넘으면 상대가 그 지점에서 넣는다.",
    "es-ES": "La canasta vale dos, o tres desde detrás del arco; la defensa puntúa con un tapón, un rebote o un robo. El balón sale por la banda y lo saca el rival desde ahí.",
    "fr-FR": "Un panier vaut deux points, trois derrière l'arc ; la défense marque par un contre, un rebond ou une interception. Ballon sorti sur la ligne de touche : l'adversaire le remet en jeu de là.",
    "id-ID": "Bola masuk bernilai dua, tiga dari luar garis; bertahan berhasil lewat blok, rebound, atau steal. Bola keluar di garis samping dan lawan memasukkannya dari sana.",
    "ms-MY": "Jaringan bernilai dua, tiga dari luar garisan; pertahanan berjaya melalui blok, rebound atau steal. Bola keluar di garisan tepi dan lawan memasukkannya dari situ.",
    "th-TH": "ลงห่วงได้ 2 แต้ม นอกเส้นสามแต้มได้ 3 ฝ่ายรับสำเร็จเมื่อบล็อก เก็บรีบาวด์ หรือขโมยบอลได้ บอลออกข้างให้ฝ่ายตรงข้ามส่งเข้าเล่นตรงจุดนั้น",
    "vi-VN": "Ghi rổ tính 2 điểm, ngoài vòng cung 3 điểm; phòng ngự thành công khi chặn bóng, bắt bật bảng hoặc cướp bóng. Bóng ra biên thì đội kia ném vào từ chỗ đó.",
}

SCORE_GOAL_HAND = {
    "en": "A goal is the whole ball over the line inside the posts, thrown from outside the goal area — a foot in the area before the ball is gone is no goal. The ball is out at the sideline, and a turnover or an offensive foul ends the attack.",
    "en-GB": "A goal is the whole ball over the line inside the posts, thrown from outside the goal area — a foot in the area before the ball is gone is no goal. The ball is out at the sideline, and a turnover or an offensive foul ends the attack.",
    "zh-CN": "球整体越过门线且从六米区外出手算进球——球未出手脚已踏入六米区则无效。球出边线由对方发球；被断球或进攻犯规即本次进攻结束。",
    "zh-TW": "球整體越過門線且從六米區外出手算進球——球未出手腳已踏入六米區則無效。球出邊線由對方發球；被斷球或進攻犯規即本次進攻結束。",
    "ja-JP": "ゴールエリア外から投げ、ボールが完全にラインを越えれば得点。リリース前にエリアを踏めばノーゴール。サイドラインを出たら相手ボール、奪われるか攻撃側の反則で攻撃終了。",
    "ko-KR": "골 에어리어 밖에서 던져 공이 라인을 완전히 넘으면 득점 — 릴리스 전에 에어리어를 밟으면 무효. 사이드라인을 넘으면 상대 공, 턴오버나 공격자 반칙이면 공격 종료.",
    "es-ES": "Es gol cuando el balón cruza entero la línea lanzado desde fuera del área — pisar el área antes de soltarlo lo anula. Sale por la banda, y una pérdida o falta de ataque termina la posesión.",
    "fr-FR": "But quand le ballon franchit entièrement la ligne, tiré de l'extérieur de la zone — un pied dans la zone avant le lâcher annule. Sortie sur la touche ; perte de balle ou faute offensive termine l'attaque.",
    "id-ID": "Gol bila bola sepenuhnya melewati garis dan dilempar dari luar area gawang; kaki masuk area sebelum bola lepas berarti tidak sah. Bola keluar di garis samping, dan turnover atau pelanggaran menyerang mengakhiri serangan.",
    "ms-MY": "Gol apabila bola melepasi garisan sepenuhnya dan dilempar dari luar kawasan gol; kaki masuk kawasan sebelum bola dilepaskan bermakna tidak sah. Bola keluar di garisan tepi, dan turnover atau kesalahan menyerang menamatkan serangan.",
    "th-TH": "เป็นประตูเมื่อบอลผ่านเส้นทั้งลูกและยิงจากนอกเขตประตู ถ้าเหยียบเขตก่อนปล่อยบอลถือว่าไม่นับ บอลออกข้างเป็นของอีกฝ่าย เสียบอลหรือฟาล์วรุกจบเกมรุก",
    "vi-VN": "Bàn thắng khi bóng qua hẳn vạch và được ném từ ngoài khu 6 m — chạm khu trước khi rời tay là không hợp lệ. Bóng ra biên thuộc đội kia; mất bóng hoặc lỗi tấn công là kết thúc đợt tấn công.",
}

SCORE_GOAL_WATER = {
    "en": "A goal is the whole ball over the line between the posts. The ball is out at the side, the other team restarts from there, and thirty seconds without a shot loses possession.",
    "en-GB": "A goal is the whole ball over the line between the posts. The ball is out at the side, the other team restarts from there, and thirty seconds without a shot loses possession.",
    "zh-CN": "球整体越过两门柱之间的门线算进球。球出边线由对方在出界处发球；30 秒内没有射门即失去球权。",
    "zh-TW": "球整體越過兩門柱之間的門線算進球。球出邊線由對方在出界處發球；30 秒內沒有射門即失去球權。",
    "ja-JP": "ボールがポスト間のラインを完全に越えれば得点。サイドを出たら相手がその地点から再開、30秒以内にシュートがなければ攻撃権を失う。",
    "ko-KR": "공이 골포스트 사이 라인을 완전히 넘으면 득점. 공이 옆으로 나가면 상대가 그 지점에서 재개하고, 30초 안에 슛이 없으면 공격권을 잃는다.",
    "es-ES": "Es gol cuando el balón cruza entero la línea entre los postes. Si sale por el lateral, el rival reanuda desde ahí, y treinta segundos sin tirar pierden la posesión.",
    "fr-FR": "But quand le ballon franchit entièrement la ligne entre les poteaux. Sortie sur le côté : l'adversaire repart de là, et trente secondes sans tir font perdre la possession.",
    "id-ID": "Gol bila bola sepenuhnya melewati garis di antara tiang. Bola keluar di samping, lawan memulai dari sana, dan tiga puluh detik tanpa tembakan berarti kehilangan bola.",
    "ms-MY": "Gol apabila bola melepasi garisan antara tiang sepenuhnya. Bola keluar di tepi, lawan memulakan dari situ, dan tiga puluh saat tanpa rembatan bermakna kehilangan bola.",
    "th-TH": "เป็นประตูเมื่อบอลผ่านเส้นระหว่างเสาทั้งลูก บอลออกข้างให้อีกฝ่ายเริ่มจากจุดนั้น และครบ 30 วินาทีไม่ได้ยิงถือว่าเสียสิทธิ์ครองบอล",
    "vi-VN": "Bàn thắng khi bóng qua hẳn vạch giữa hai cột. Bóng ra biên thì đội kia phát lại từ đó, và ba mươi giây không dứt điểm là mất quyền kiểm soát bóng.",
}

SCORE_GOAL_HOCKEY = {
    "en": "A goal only counts if the ball is touched inside the shooting circle — a shot from outside it is not a goal however it goes in. The ball out over the sideline is a free hit to the other team from where it left.",
    "en-GB": "A goal only counts if the ball is touched inside the shooting circle — a shot from outside it is not a goal however it goes in. The ball out over the sideline is a free hit to the other team from where it left.",
    "zh-CN": "只有在射门圆圈内触球后进的才算进球——圈外射入无论多漂亮都不算。球出边线由对方在出界处发任意球。",
    "zh-TW": "只有在射門圓圈內觸球後進的才算進球——圈外射入無論多漂亮都不算。球出邊線由對方在出界處發任意球。",
    "ja-JP": "シューティングサークル内で触れたボールだけが得点になる——サークル外からのシュートは入っても得点にならない。サイドラインを出たら、その地点から相手のフリーヒット。",
    "ko-KR": "슈팅 서클 안에서 건드린 공만 득점으로 인정된다 — 서클 밖에서의 슛은 들어가도 무효. 사이드라인을 넘으면 그 지점에서 상대의 프리히트.",
    "es-ES": "Solo es gol si la bola se toca dentro del círculo de tiro: un disparo desde fuera no vale por muy bien que entre. Bola fuera por la banda, golpe franco para el rival desde donde salió.",
    "fr-FR": "Un but ne compte que si la balle est touchée dans le cercle : un tir de l'extérieur ne vaut rien, même s'il rentre. Sortie sur la touche : coup franc pour l'adversaire à l'endroit de la sortie.",
    "id-ID": "Gol hanya sah jika bola disentuh di dalam lingkaran tembak; tembakan dari luar tidak dihitung. Bola keluar garis samping berarti free hit bagi lawan dari tempat bola keluar.",
    "ms-MY": "Gol hanya sah jika bola disentuh dalam bulatan tembakan; rembatan dari luar tidak dikira. Bola keluar garisan tepi bermakna free hit untuk lawan dari tempat bola keluar.",
    "th-TH": "จะเป็นประตูได้ต้องสัมผัสบอลในวงยิงเท่านั้น ยิงจากนอกวงไม่นับ บอลออกเส้นข้างให้ฝ่ายตรงข้ามเล่นฟรีฮิตตรงจุดที่ออก",
    "vi-VN": "Chỉ tính bàn khi bóng được chạm trong vòng cấm ghi bàn — sút từ ngoài vòng không tính dù vào lưới. Bóng ra biên thì đội kia được đánh phạt tại chỗ bóng ra.",
}

SCORE_TRY = {
    "en": "A try is the ball pressed down on the ground in the in-goal; a tackle is made below the shoulders and the ball must be released. Ball or carrier over the touchline ends the phase and the other side throws in.",
    "en-GB": "A try is the ball pressed down on the ground in the in-goal; a tackle is made below the shoulders and the ball must be released. Ball or carrier over the touchline ends the phase and the other side throws in.",
    "zh-CN": "在达阵区内把球按到地面算达阵；擒抱必须在肩以下，被抱倒后必须放球。球或持球人出边线即本波次结束，由对方掷界外球。",
    "zh-TW": "在達陣區內把球按到地面算達陣；擒抱必須在肩以下，被抱倒後必須放球。球或持球人出邊線即本波次結束，由對方擲界外球。",
    "ja-JP": "インゴールでボールを地面に押さえればトライ。タックルは肩より下で、倒されたらボールを離す。ボールか保持者がタッチラインを出たらそのフェーズは終わり、相手のラインアウト。",
    "ko-KR": "인골에서 공을 땅에 눌러야 트라이. 태클은 어깨 아래로 하고, 잡히면 공을 놓아야 한다. 공이나 볼 캐리어가 터치라인을 넘으면 페이즈가 끝나고 상대가 스로인한다.",
    "es-ES": "Un ensayo es apoyar el balón en el suelo del in-goal; el placaje va por debajo de los hombros y hay que soltar el balón. Balón o portador fuera de la línea de touche acaba la fase y saca el rival.",
    "fr-FR": "Un essai, c'est le ballon aplati au sol dans l'en-but ; le plaquage se fait sous les épaules et le ballon doit être libéré. Ballon ou porteur en touche : la phase s'arrête et l'adversaire lance.",
    "id-ID": "Try adalah bola ditekan ke tanah di area in-goal; tekel di bawah bahu dan bola harus dilepas. Bola atau pembawa keluar garis samping mengakhiri fase dan lawan melempar ke dalam.",
    "ms-MY": "Try ialah bola ditekan ke tanah di kawasan in-goal; tekel di bawah bahu dan bola mesti dilepaskan. Bola atau pembawa keluar garisan tepi menamatkan fasa dan lawan membaling masuk.",
    "th-TH": "ทรายคือการกดบอลลงพื้นในเขตอินโกล แท็กเกิลต้องต่ำกว่าไหล่และต้องปล่อยบอลเมื่อถูกล้ม บอลหรือคนถือบอลออกเส้นข้างจบเฟสนั้น ฝ่ายตรงข้ามโยนเข้าเล่น",
    "vi-VN": "Try là ấn bóng xuống đất trong khu in-goal; tắc bóng phải dưới vai và người bị tắc phải nhả bóng. Bóng hoặc người cầm bóng ra biên là kết thúc pha, đội kia ném biên.",
}

SCORE_POINT_NET = {
    "en": "A ball landing inside the lines wins the point; out, into the net, or a second bounce loses it. Serve changes every two points, and a ball on the line is in.",
    "en-GB": "A ball landing inside the lines wins the point; out, into the net, or a second bounce loses it. Serve changes every two points, and a ball on the line is in.",
    "zh-CN": "球落在界内得分；出界、下网或落地两次失分。每两分换发球，压线算界内。",
    "zh-TW": "球落在界內得分；出界、下網或落地兩次失分。每兩分換發球，壓線算界內。",
    "ja-JP": "ライン内に落ちれば得点、アウト・ネット・ツーバウンドは失点。2点ごとにサーブ交代、ライン上はイン。",
    "ko-KR": "라인 안에 떨어지면 득점, 아웃·네트·투바운드는 실점. 2점마다 서브가 바뀌고, 라인에 걸치면 인이다.",
    "es-ES": "La bola que cae dentro gana el punto; fuera, en la red o segundo bote lo pierde. El saque cambia cada dos puntos y la bola en la línea es buena.",
    "fr-FR": "La balle qui tombe dans les limites gagne le point ; dehors, dans le filet ou au deuxième rebond, il est perdu. Service toutes les deux points, balle sur la ligne est bonne.",
    "id-ID": "Bola jatuh di dalam garis memenangkan poin; keluar, ke net, atau pantul kedua kehilangan poin. Servis bergantian tiap dua poin, bola di garis dianggap masuk.",
    "ms-MY": "Bola jatuh dalam garisan memenangi mata; keluar, ke jaring, atau lantunan kedua kehilangan mata. Servis bertukar setiap dua mata, bola pada garisan dikira masuk.",
    "th-TH": "บอลลงในเส้นได้แต้ม ออก ติดเน็ต หรือเด้งสองครั้งเสียแต้ม สลับเสิร์ฟทุกสองแต้ม บอลโดนเส้นถือว่าดี",
    "vi-VN": "Bóng rơi trong vạch thì thắng điểm; ra ngoài, chạm lưới hoặc nảy hai lần là mất điểm. Đổi giao bóng sau mỗi hai điểm, bóng chạm vạch là trong sân.",
}
