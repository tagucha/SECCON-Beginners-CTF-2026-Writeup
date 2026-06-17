# gpt-5.5に書かせました。

from fpylll import IntegerMatrix, LLL, CVP

p = 2**56 - 5
d = 9
N = 16
CHUNK_SIZE = 6

M = [
    (66670289633989123, 65549514315400540),
    (47866332048237268, 8240241565196430),
    (3297434288428048, 7332454645939087),
    (71573658226964891, 38154276305948413),
    (71929715653433723, 58155850654517076),
    (2056394791681086, 30160984441000410),
    (15940343931701997, 17120059464995430),
    (65533961217990466, 47757529084283168),
    (63596524453162845, 52746879166960887),
    (27988476998231307, 13815434921518651),
    (48869754696545371, 52022939095369274),
    (24897568004524538, 22405555292909308),
    (52801756112313931, 48213594387859606),
    (51122532884517240, 70457511792794826),
    (11875735483495049, 1360588394024915),
    (29715188478490161, 71269048070624534),
    (3391564649218441, 58579541284523349),
    (56070872790673905, 34794914171393657),
    (39440497475132306, 14750870419448571),
    (44511195681706461, 8782359570821913),
    (51308270229712889, 30201825037137892),
    (10790085877447707, 23109002369633121),
    (52822817408693162, 652326482594892),
    (58622413301095385, 68017486288977517),
    (29062119069543159, 10222468856864978),
    (63705667919470955, 38030807993157012),
    (39286472520317729, 49212759792018361),
    (48615090782171081, 18815807570300544),
    (48098058298248281, 60527673508166866),
    (44395336162397255, 47941184006948437),
    (65697566165868415, 58903386901116584),
    (21450705129822598, 68681445079526808),
    (29997975294363653, 14491293582734585),
    (16730667442081607, 11190761026794882),
    (22054934278608981, 69281681048206263),
    (25488019748353120, 14333564956265072),
    (35507170252324898, 21438683556278428),
    (46056309517562278, 21841033600683486),
    (63200019729211654, 46975779833126602),
    (60390999279750379, 64272040369157390),
    (30951752170662072, 45546487233988139),
    (34042764170730633, 66455407871545196),
    (29847331268302676, 42055877724734176),
    (28216024603396536, 32116042120317343),
    (44617717023607745, 48754972005681599),
    (10083469696124555, 14097016944462303),
    (2139056798540668, 663327504951244),
    (14040877363643787, 37851711976931923),
    (17054414342937569, 33517566052979243),
    (8238029886065847, 11106621908360984),
    (6278415303828344, 58153704625590892),
    (46168127635187086, 68207869532744438),
    (50819530059420731, 3346111399058802),
    (53101510379690135, 66055650675521646),
    (2014920098228548, 31115769574896925),
    (26564614991596266, 38920366331171105),
    (28064281985868050, 27153251160409332),
    (9955507594876099, 3775382415392399),
    (53229347926987717, 59080275818512220),
    (18551635300303989, 20403752964783104),
    (29825029396964081, 34739884557152290),
    (1152551391336408, 11797809704974176),
    (42425971569777201, 31898449829059610),
    (65219708156548647, 25365860762196651),
    (56155988874480856, 60310674634373672),
    (27028446506201204, 57107252511520259),
    (15694076462060293, 52389434767626488),
    (68416771320286114, 63354139496008359),
    (69965584251334474, 28243632622869763),
    (66819170526647233, 49884633866918916),
    (4345634342712410, 31164985069814526),
    (47507989612233339, 5983484310339395),
    (9303108578832632, 19754675882423486),
    (46285054002407619, 43532950099522221),
    (7382288207418669, 67383996076249829),
    (6197664374510810, 23142687842347564),
    (67480720930365822, 29857159922901278),
    (65942894802245287, 68522532935640146),
    (32547428093416107, 22998850819749187),
    (2926351861142840, 39233788819858593),
    (65227080576840607, 56642092736108777),
]

C = [
    (54649704974770140, 41003910305633316),
    (57086486018359680, 7641641798901328),
    (30798454400437486, 39525449878779876),
    (55884777323717003, 14422454418349844),
    (18346875983950092, 41919780939967310),
    (13623520666864272, 33596150788223854),
    (9029527223588837, 28892450222298080),
    (69410081757122703, 29063972128496967),
    (27969775375995859, 63266141206685661),
    (41576861401531506, 51279566041810558),
    (7084326790655086, 70154033453674772),
    (48933256738656108, 64460953477033916),
    (31536040920616254, 70566923094425432),
    (63689243044712361, 6477420590460575),
    (20165132772686910, 15321906875396175),
    (61000660724607210, 39689358356670318),
]


def k_add(x, y):
    return ((x[0] + y[0]) % p, (x[1] + y[1]) % p)


def k_sub(x, y):
    return ((x[0] - y[0]) % p, (x[1] - y[1]) % p)


def k_mul(x, y):
    a, b = x
    c, e = y
    return ((a * c - b * e) % p, (a * e + b * c) % p)


def mat_mul(A, B):
    out = [(0, 0)] * (d * d)
    for r in range(d):
        for c in range(d):
            acc = (0, 0)
            for k in range(d):
                acc = k_add(acc, k_mul(A[r * d + k], B[k * d + c]))
            out[r * d + c] = acc
    return out


def mat_row(A, r):
    return A[r * d:(r + 1) * d]


def dot(row, state):
    acc = (0, 0)
    for a, b in zip(row, state):
        acc = k_add(acc, k_mul(a, b))
    return acc


def row_coeffs(row):
    real = [0] * (2 * d)
    imag = [0] * (2 * d)

    for col in range(d):
        a, b = row[col]

        # (a + b*i)(x + y*i) = (a*x - b*y) + (a*y + b*x)*i
        real[col] = (real[col] + a) % p
        real[d + col] = (real[d + col] - b) % p

        imag[col] = (imag[col] + b) % p
        imag[d + col] = (imag[d + col] + a) % p

    return real, imag


def rref_mod(A, b):
    aug = [row[:] + [bb % p] for row, bb in zip(A, b)]
    m = len(aug)
    n = len(aug[0]) - 1
    pivots = []
    r = 0

    for c in range(n):
        pivot = None
        for rr in range(r, m):
            if aug[rr][c] % p != 0:
                pivot = rr
                break

        if pivot is None:
            continue

        aug[r], aug[pivot] = aug[pivot], aug[r]

        inv = pow(aug[r][c] % p, -1, p)
        aug[r] = [(v * inv) % p for v in aug[r]]

        for rr in range(m):
            if rr == r:
                continue
            factor = aug[rr][c] % p
            if factor == 0:
                continue
            aug[rr] = [
                (aug[rr][cc] - factor * aug[r][cc]) % p
                for cc in range(n + 1)
            ]

        pivots.append(c)
        r += 1

    return aug, pivots


def solve_affine_space(A, b):
    rref, pivots = rref_mod(A, b)
    n = len(A[0])
    free_cols = [c for c in range(n) if c not in pivots]

    x0 = [0] * n
    for row_idx, col in enumerate(pivots):
        x0[col] = rref[row_idx][n] % p

    basis = []
    for free_col in free_cols:
        v = [0] * n
        v[free_col] = 1
        for row_idx, col in enumerate(pivots):
            v[col] = (-rref[row_idx][free_col]) % p
        basis.append(v)

    return x0, basis, pivots


def vec_to_state(v):
    return [(v[idx] % p, v[d + idx] % p) for idx in range(d)]


def bytes_to_long(bs):
    return int.from_bytes(bs, "big")


def int_to_chunk(x):
    return int(x).to_bytes(CHUNK_SIZE, "big")


def is_printable_chunk(x):
    if not (0 <= x < 256**CHUNK_SIZE):
        return False
    bs = int_to_chunk(x)
    return all(0x20 <= b <= 0x7e for b in bs)


def build_linear_system():
    rows = []
    rhs = []
    P = M[:]
    prefix = bytes_to_long(b"ctf4b{")

    for j in range(N):
        row = mat_row(P, 0)
        real_coeff, imag_coeff = row_coeffs(row)
        c_re, c_im = C[j]

        # m_j is real-only, so the imaginary part gives a state equation.
        rows.append(imag_coeff)
        rhs.append(c_im)

        # chunk 0 is known exactly: b"ctf4b{".
        if j == 0:
            rows.append(real_coeff)
            rhs.append((c_re - prefix) % p)

        P = mat_mul(P, M)

    return rows, rhs


def build_message_forms(x0, kernel_basis):
    if len(kernel_basis) != 1:
        raise ValueError(f"expected kernel dimension 1, got {len(kernel_basis)}")

    base_state = vec_to_state(x0)
    kernel_state = vec_to_state(kernel_basis[0])

    forms = []
    P = M[:]

    for j in range(N):
        row = mat_row(P, 0)
        base_output = dot(row, base_state)
        kernel_output = dot(row, kernel_state)

        base_m = k_sub(C[j], base_output)
        kernel_m = ((-kernel_output[0]) % p, (-kernel_output[1]) % p)

        if base_m[1] != 0:
            raise ValueError(f"base message has non-zero imaginary part at chunk {j}")
        if kernel_m[1] != 0:
            raise ValueError(f"kernel message has non-zero imaginary part at chunk {j}")

        # m_j = alpha + beta*t mod p
        forms.append((base_m[0], kernel_m[0]))
        P = mat_mul(P, M)

    return forms


def validate_t(forms, t):
    chunks = []

    for alpha, beta in forms:
        x = (alpha + beta * t) % p
        if not is_printable_chunk(x):
            return None
        chunks.append(int_to_chunk(x))

    flag = b"".join(chunks)
    if not flag.startswith(b"ctf4b{"):
        return None
    if not flag.endswith(b"}"):
        return None

    return flag


def closest_vector_fpylll(basis, target):
    B = IntegerMatrix(len(basis), len(basis[0]))
    for r in range(len(basis)):
        for c in range(len(basis[0])):
            B[r, c] = int(basis[r][c])

    LLL.reduction(B)
    v = CVP.closest_vector(B, [int(x) for x in target])
    return [int(x) for x in v]


def recover_t_by_cvp(forms):
    idx = [j for j, (_, beta) in enumerate(forms) if beta % p != 0]

    for scale in [1, 2, 4, 8, 16, 64, 256, 1024]:
        n = len(idx)
        basis = []

        for r in range(n):
            row = [0] * (n + 1)
            row[r] = p * scale
            basis.append(row)

        t_row = [forms[j][1] * scale for j in idx]
        t_row.append(1)
        basis.append(t_row)

        center = 2**47
        targets = [
            [(-forms[j][0]) * scale for j in idx] + [0],
            [(center - forms[j][0]) * scale for j in idx] + [0],
            [((center - forms[j][0]) % p) * scale for j in idx] + [0],
        ]

        for target in targets:
            v = closest_vector_fpylll(basis, target)
            t = v[-1] % p
            flag = validate_t(forms, t)
            if flag is not None:
                return t, flag

        print(f"[-] scale {scale} failed")

    return None, None


def main():
    rows, rhs = build_linear_system()
    x0, kernel_basis, pivots = solve_affine_space(rows, rhs)
    forms = build_message_forms(x0, kernel_basis)

    print("variables over GF(p):", 2 * d)
    print("equations over GF(p):", len(rows))
    print("rank:", len(pivots))
    print("kernel dimension:", len(kernel_basis))

    t, flag = recover_t_by_cvp(forms)
    if flag is None:
        raise RuntimeError("failed to recover flag")

    print("t =", t)
    print("flag:")
    print(flag.decode())


if __name__ == "__main__":
    main()
