# 06 — 100 Viral Hook Templates

These are battle-tested **first-1.5-seconds** hooks for short-form. They are
burned on-screen as text **and** used as the first line of the caption.

Each hook has:
- **ID** for tracking which hook produced which view performance,
- **Category** (matches viral framework F1–F7),
- **Service tags** so the system picks hooks that match the clip,
- **EN + RU** variants for bilingual operators,
- **Slot pattern** so the LLM can rephrase without losing the structure.

> The factory should ALWAYS prefer to use a tracked template hook over an
> open-ended generation. Templates win 4–6× more on average because their
> structure has been pressure-tested.

Hooks are stored in `hooks` table in Supabase with cooling-period tracking
(see `docs/02-n8n-workflows.md` §9 anti-fatigue).

---

## Category 1 — Abandoned Property (H001–H010)

Triggers: forbidden reveal, curiosity, scale.
Services: OVR, CLR, MNT.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H001  | Nobody had touched this yard in {N} years.                            | На этом участке никто не был {N} лет.                                    |
| H002  | They abandoned this property — we got the keys today.                 | Этот участок бросили — ключи нам отдали сегодня.                         |
| H003  | The neighbors couldn't even see the house anymore.                    | Соседи уже не видели дом за этим всем.                                   |
| H004  | The owner sent us a photo. We didn't believe it.                      | Хозяин прислал фото. Мы не поверили.                                     |
| H005  | This used to be a front lawn.                                         | Раньше это был передний газон.                                           |
| H006  | We were told the gate was "somewhere on the left."                    | Сказали, что ворота "где-то слева".                                      |
| H007  | The grass was taller than I am.                                       | Трава была выше меня.                                                    |
| H008  | We almost cancelled the job when we saw it.                           | Мы чуть не отказались от заказа, когда приехали.                         |
| H009  | This place hadn't seen a mower since {YEAR}.                          | Сюда не заезжал триммер с {YEAR}-го года.                                |
| H010  | The house was inside there. We promise.                               | Где-то там был дом. Серьёзно.                                            |

---

## Category 2 — Extreme Grass / Overgrowth (H011–H020)

Triggers: contrast, scale, mastery.
Services: MOW, OVR.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H011  | {HEIGHT}-meter grass in {HOURS} hours. Watch.                          | {HEIGHT}-метровая трава за {HOURS} часов. Смотри.                         |
| H012  | First pass cleared {X} %. Wait for pass two.                          | Первый проход — {X}%. Жди второй.                                        |
| H013  | The grass had its own grass.                                          | У этой травы была своя трава.                                            |
| H014  | We had to break out the heavy stuff for this one.                     | Сюда пришлось тащить тяжёлую технику.                                    |
| H015  | I haven't seen a yard like this in {N} years.                         | Такого участка я не видел уже {N} лет.                                   |
| H016  | The drone couldn't even find the path.                                | Даже дрон не нашёл тропинку.                                             |
| H017  | This is exactly what a yard looks like after {N} summers untouched.   | Вот так выглядит участок после {N} лет без ухода.                        |
| H018  | The brushcutter survived. Barely.                                     | Триммер выжил. Еле-еле.                                                  |
| H019  | They wanted us to "just tidy the front." Then we saw the back.        | Заказывали "немного подровнять перед". Потом увидели задний двор.        |
| H020  | Bet you can't tell what's hiding in this grass.                       | Спорим, не угадаешь, что прячется в этой траве.                          |

---

## Category 3 — Satisfying Cleanup (H021–H030)

Triggers: contrast, ASMR, mastery.
Services: CLN, OVR, CLR, PLW.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H021  | This is going to be oddly satisfying.                                 | Сейчас будет странно приятно.                                            |
| H022  | Headphones on. Sound up. You're welcome.                              | Наушники надеть. Громче. Не за что.                                      |
| H023  | The cleanest part of my day.                                          | Самая чистая часть моего дня.                                            |
| H024  | This is what {N} liters of pressure can do.                            | Вот что делает {N} литров под давлением.                                 |
| H025  | One pass. That's all it took.                                         | Один проход. И всё.                                                      |
| H026  | I could watch this all day.                                           | Я мог бы смотреть это весь день.                                         |
| H027  | The "before" really sells it.                                         | "До" — главное в этом видео.                                             |
| H028  | Please tell me this is as satisfying for you as for me.               | Скажите мне, что вам тоже приятно это смотреть.                          |
| H029  | This is what a clean property is supposed to look like.               | Вот так должен выглядеть нормальный участок.                             |
| H030  | The transformation no one expected.                                   | Превращение, которого никто не ждал.                                     |

---

## Category 4 — "You Won't Believe This" (H031–H040)

Triggers: curiosity, scale.
Services: any.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H031  | You won't believe what was under this.                                | Не поверишь, что было под этим.                                          |
| H032  | We weren't supposed to find this.                                     | Мы не должны были это найти.                                             |
| H033  | Wait for it.                                                          | Дождись конца.                                                           |
| H034  | I had to do a double-take.                                            | Пришлось переспросить дважды.                                            |
| H035  | This isn't what the owner described on the phone.                     | По телефону хозяин описал это совсем иначе.                              |
| H036  | I've been doing this {N} years and I've never seen this.              | Я в этом деле {N} лет — такого ещё не видел.                             |
| H037  | The reveal at 0:15 is wild.                                           | На 15-й секунде — то самое.                                              |
| H038  | Don't scroll yet. Watch what happens.                                 | Не пролистывай. Смотри, что будет.                                       |
| H039  | This is not what we expected to clear.                                | Это вообще не то, что мы готовились убирать.                             |
| H040  | The owner thought it was just a lawn.                                 | Хозяин думал, что это просто газон.                                      |

---

## Category 5 — Expensive Transformations (H041–H050)

Triggers: status, curiosity, debate-bait.
Services: any.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H041  | Guess how much this cost. Comment first.                              | Угадай цену. Пиши в комментариях.                                        |
| H042  | We quoted ${PRICE}. They said yes.                                    | Мы назвали {PRICE} ₽. Согласились.                                       |
| H043  | This is what {PRICE} ₽ of cleanup looks like.                          | Вот так выглядит уборка на {PRICE} ₽.                                    |
| H044  | The previous "cheap" guy charged {X}× more.                            | Прошлый "дешёвый" подрядчик взял в {X} раза больше.                       |
| H045  | Real talk: this took {HOURS} hours and {N} workers.                    | Честно: {HOURS} часов и {N} человек.                                     |
| H046  | The cheapest part of this job? The fuel.                              | Самое дешёвое в этой работе — топливо.                                   |
| H047  | A realtor told them to fix this. Or drop the price by ${AMOUNT}.       | Риелтор сказал: либо приведите в порядок, либо минус {AMOUNT}.            |
| H048  | We're not the cheapest. Here's why.                                   | Мы не самые дешёвые. Сейчас покажу почему.                               |
| H049  | Pay once. Look at this for a decade.                                  | Один раз заплати. Десять лет любуйся.                                    |
| H050  | The "free" quote took longer than the job.                            | "Бесплатная" оценка заняла больше времени, чем сама работа.              |

---

## Category 6 — Dangerous Trees / Risky Work (H051–H060)

Triggers: tension, status, mastery.
Services: TRE, STM.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H051  | This tree was about to fall on the house.                             | Это дерево вот-вот упало бы на дом.                                      |
| H052  | The wrong cut here = $50k of damage.                                  | Неправильный пропил здесь — минус целое состояние.                       |
| H053  | We had one chance to drop it right.                                   | У нас был один шанс уронить его правильно.                               |
| H054  | The branch was over the power line.                                   | Ветка лежала на проводах.                                                |
| H055  | They wanted a "small trim." This is what we found.                    | Просили "слегка подрезать". Вот что нашли.                               |
| H056  | This is why you don't DIY tree removal.                               | Вот почему не надо валить дерево самому.                                 |
| H057  | The stump was deeper than the foundation.                             | Корень был глубже фундамента.                                            |
| H058  | One man. One chainsaw. {N} meters.                                    | Один человек. Одна бензопила. {N} метров.                                |
| H059  | The wind almost ruined this.                                          | Ветер чуть всё не испортил.                                              |
| H060  | I held my breath for 12 seconds.                                      | Я задержал дыхание на 12 секунд.                                         |

---

## Category 7 — Swamp-Like Pools (H061–H070)

Triggers: forbidden reveal, contrast.
Services: POO.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H061  | This is supposed to be a swimming pool.                               | Это вообще-то бассейн.                                                   |
| H062  | The water was BLACK.                                                  | Вода была ЧЁРНАЯ.                                                        |
| H063  | I don't want to know what's at the bottom.                            | Я не хочу знать, что на дне.                                             |
| H064  | We pulled {N} bags out before we even started.                        | Мы вытащили {N} мешков до того, как начали.                              |
| H065  | The neighbors said something moved in there.                          | Соседи говорили, что там что-то двигалось.                               |
| H066  | This thing hadn't been opened in {N} years.                           | Эту крышку не снимали {N} лет.                                           |
| H067  | The "after" doesn't even look like the same pool.                     | "После" — будто другой бассейн.                                          |
| H068  | First time the bottom was visible in {N} summers.                     | Дно увидели впервые за {N} лет.                                          |
| H069  | The chemistry alone was a nightmare.                                  | Один только баланс химии — это кошмар.                                   |
| H070  | They were about to fill it with concrete.                             | Хотели уже залить бетоном.                                               |

---

## Category 8 — "Watch Till the End" / Loop Traps (H071–H080)

Triggers: curiosity, replay.
Services: any.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H071  | The ending is everything.                                             | Конец — самое главное.                                                   |
| H072  | I almost didn't post this.                                            | Я чуть это не выложил.                                                   |
| H073  | Watch the last 3 seconds twice.                                       | Смотри последние 3 секунды дважды.                                       |
| H074  | The loop is intentional. Try not to re-watch.                         | Зацикливается специально. Попробуй не пересмотреть.                      |
| H075  | Don't skip. The reveal is at 0:18.                                    | Не листай. На 18-й секунде — то самое.                                   |
| H076  | I cut this {N} times to get the timing right.                         | Перерезал {N} раз, чтобы попасть в ритм.                                 |
| H077  | The hidden detail in the corner: did you see it?                      | Деталь в углу — заметил?                                                 |
| H078  | This took {HOURS} hours. The video is {S} seconds.                     | Работали {HOURS} часов. Видео — {S} секунд.                              |
| H079  | The audio at 0:09 is what sells this.                                 | На 9-й секунде — тот самый звук.                                         |
| H080  | One frame change — but you'll feel it.                                | Один кадр поменяли — но ты это почувствуешь.                             |

---

## Category 9 — Local Pride & Authority (H081–H090)

Triggers: status, locality, trust.
Services: any.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H081  | Cleanest yard in {CITY} this week.                                    | Самый чистый участок в {CITY} на этой неделе.                            |
| H082  | If you live in {CITY}, you've probably driven past this.              | Если ты из {CITY}, ты точно мимо этого ездил.                            |
| H083  | We're the only ones in {CITY} with this machine.                      | Такой техники в {CITY} больше ни у кого нет.                             |
| H084  | The {CITY} crew. Day {N} of {N}.                                       | Команда {CITY}. День {N} из {N}.                                         |
| H085  | This is on the edge of {NEIGHBORHOOD}.                                | Это на границе {NEIGHBORHOOD}.                                           |
| H086  | Three jobs in {CITY} this week. This was #1.                          | Три заказа в {CITY} за неделю. Этот — самый красивый.                    |
| H087  | They called four other companies first. We came same day.             | Звонили четверым до нас. Мы приехали в тот же день.                      |
| H088  | Our truck has done {N} km in {CITY} this month.                       | Наш грузовик проехал {N} км по {CITY} за месяц.                          |
| H089  | This is what we do here. Locally. Properly.                           | Вот что мы делаем. По-нашему. По-человечески.                            |
| H090  | If you're in {CITY} and you've been putting it off — this is your sign.| Если ты в {CITY} и откладываешь — это знак.                              |

---

## Category 10 — Numbers, Lists, Speed (H091–H100)

Triggers: curiosity, status, debate.
Services: any.

| ID    | EN                                                                    | RU                                                                       |
| ----- | --------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| H091  | {N} kilos of branches in {M} minutes.                                 | {N} килограммов веток за {M} минут.                                      |
| H092  | 5 mistakes the last guy made on this property.                        | 5 ошибок, которые сделал предыдущий "мастер".                            |
| H093  | We cleared {N} m² today. Fastest of the season.                       | Очистили {N} м² за день. Самый быстрый рекорд сезона.                    |
| H094  | The 3-step routine that fixed this pool in 4 hours.                   | Три шага, которые вернули этот бассейн к жизни за 4 часа.                |
| H095  | One job, two cameras, zero edits. Watch.                              | Одна работа, две камеры, без монтажа. Смотри.                            |
| H096  | This is the {N}th yard like this we've cleared in {CITY}.              | Это {N}-й такой участок в {CITY}, который мы очистили.                   |
| H097  | The math: {N} hours × {N} workers × 1 result.                          | Математика: {N} часов × {N} человек × 1 результат.                       |
| H098  | We track every job. This was our fastest in {CATEGORY}.               | Мы считаем каждый заказ. Этот — самый быстрый по {CATEGORY}.             |
| H099  | Three tools. Two passes. One transformed yard.                        | Три инструмента. Два прохода. Один обновлённый участок.                  |
| H100  | The before-and-after numbers will surprise you. Wait for it.          | Цифры до и после — удивят. Дождись.                                      |

---

## How the system uses these hooks

1. The hook generator (`prompts/hook-generator.md`) is forced to **pick by
   ID** from this list 80 % of the time, and **invent in this style** 20 %
   of the time.
2. `{N}`, `{HOURS}`, `{PRICE}`, `{CITY}`, etc. are filled from the clip's
   tags / job metadata (see `docs/04-ai-pipeline.md`).
3. A hook can only be reused on the same platform after a **30-day cool-off**.
4. Hook performance is logged: avg 3-s retention per hook, per platform.
   The bottom 10 % of hooks are auto-retired and excluded from the bank.
5. Operators can flag a hook as "always available" if it works exceptionally
   well in their specific city / market.

The bank is **append-only**. The LLM generates new candidates weekly
(in workflow 06) — they're stored as draft hooks. Once a draft hook has been
posted 5+ times and beats the 50th-percentile retention, it's promoted to
"core" and gets an H{N} ID.
