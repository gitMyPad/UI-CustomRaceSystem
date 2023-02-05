//$ noimport
library Init

module Init
    static if thistype.onStartup.exists then
    private static method startup takes nothing returns nothing
        call thistype.onStartup()
    endmethod
    endif
    private static method onInit takes nothing returns nothing
        static if thistype.init.exists then
            call thistype.init()
        endif
        static if thistype.onStartup.exists then
            call TimerStart(CreateTimer(), 0.00, false, function thistype.startup)
        endif
    endmethod
endmodule

endlibrary