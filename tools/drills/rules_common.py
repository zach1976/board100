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

# A game: it restarts itself.
GAME_RULES = {
    "en": "After a goal or the ball going out, restart from the keeper or the touchline and keep playing; four-minute games, then swap ends or opponents.",
    "en-GB": "After a goal or the ball going out, restart from the keeper or the touchline and keep playing; four-minute games, then swap ends or opponents.",
    "zh-CN": "进球或球出界后，从门将或边线重新开始，比赛不停；每局 4 分钟，局间换边或换对手。",
    "zh-TW": "進球或球出界後，從門將或邊線重新開始，比賽不停；每局 4 分鐘，局間換邊或換對手。",
    "ja-JP": "得点かボールアウトの後は、キーパーかタッチラインから再開して止めない。1ゲーム4分、終わったらエンドか相手を交代。",
    "ko-KR": "골이 나거나 공이 나가면 골키퍼나 터치라인에서 다시 시작하고 멈추지 않는다. 한 게임 4분, 끝나면 진영이나 상대를 바꾼다.",
    "es-ES": "Tras un gol o balón fuera, se reanuda desde el portero o la banda sin parar; partidos de cuatro minutos, luego cambio de campo o de rival.",
    "fr-FR": "Après un but ou une sortie, on relance du gardien ou de la touche sans s'arrêter ; matchs de quatre minutes, puis on change de côté ou d'adversaire.",
    "id-ID": "Setelah gol atau bola keluar, mulai lagi dari kiper atau garis tepi dan terus bermain; empat menit per gim, lalu tukar sisi atau lawan.",
    "ms-MY": "Selepas gol atau bola keluar, mula semula dari penjaga gol atau garisan tepi dan terus bermain; empat minit setiap perlawanan, kemudian tukar sisi atau lawan.",
    "th-TH": "หลังได้ประตูหรือบอลออก เริ่มใหม่จากผู้รักษาประตูหรือเส้นข้างแล้วเล่นต่อไม่หยุด เกมละ 4 นาที แล้วสลับแดนหรือสลับคู่แข่ง",
    "vi-VN": "Sau bàn thắng hoặc bóng ra ngoài, bắt đầu lại từ thủ môn hoặc đường biên và chơi tiếp; mỗi trận 4 phút rồi đổi sân hoặc đổi đối thủ.",
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
