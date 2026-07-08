use super::Terminal;
use crate::parser::Function;

impl Terminal {
    pub fn execute(&mut self, fun: Function) {
        use Function::*;

        match fun {
            Bs => {
                self.bs();
            }

            Cbt(n) => {
                self.cbt(n);
            }

            Cha(n) => {
                self.cha(n);
            }

            Cht(n) => {
                self.cht(n);
            }

            Cnl(n) => {
                self.cnl(n);
            }

            Cpl(n) => {
                self.cpl(n);
            }

            Cr => {
                self.cr();
            }

            Ctc(mode) => {
                self.ctc(mode);
            }

            Cub(n) => {
                self.cub(n);
            }

            Cud(n) => {
                self.cud(n);
            }

            Cuf(n) => {
                self.cuf(n);
            }

            Cup(row, col) => {
                self.cup(row, col);
            }

            Cuu(n) => {
                self.cuu(n);
            }

            Dch(n) => {
                self.dch(n);
            }

            Decaln => {
                self.decaln();
            }

            Decrc => {
                self.rc();
            }

            Decrst(modes) => {
                self.decrst(modes);
            }

            Decsc => {
                self.sc();
            }

            Decset(modes) => {
                self.decset(modes);
            }

            Decstbm(top, bottom) => {
                self.decstbm(top, bottom);
            }

            Decstr => {
                self.decstr();
            }

            Dl(n) => {
                self.dl(n);
            }

            Ech(n) => {
                self.ech(n);
            }

            Ed(mode) => {
                self.ed(mode);
            }

            El(mode) => {
                self.el(mode);
            }

            G1d4(charset) => {
                self.g1d4(charset);
            }

            Gzd4(charset) => {
                self.gzd4(charset);
            }

            Ht => {
                self.ht();
            }

            Hts => {
                self.hts();
            }

            Ich(n) => {
                self.ich(n);
            }

            Il(n) => {
                self.il(n);
            }

            Lf => {
                self.lf();
            }

            Nel => {
                self.nel();
            }

            Print(ch) => {
                self.print(ch);
            }

            Rep(n) => {
                self.rep(n);
            }

            Ri => {
                self.ri();
            }

            Ris => {
                self.ris();
            }

            Rm(modes) => {
                self.rm(modes);
            }

            Scorc => {
                self.rc();
            }

            Scosc => {
                self.sc();
            }

            Sd(n) => {
                self.sd(n);
            }

            Sgr(params) => {
                self.sgr(params);
            }

            Si => {
                self.si();
            }

            Sm(modes) => {
                self.sm(modes);
            }

            So => {
                self.so();
            }

            Su(n) => {
                self.su(n);
            }

            Tbc(mode) => {
                self.tbc(mode);
            }

            Vpa(n) => {
                self.vpa(n);
            }

            Vpr(n) => {
                self.vpr(n);
            }

            Xtwinops(op) => {
                self.xtwinops(op);
            }
        }
    }
}
