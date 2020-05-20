from __future__ import unicode_literals
from oh_settings import *
from insert_code import *

OH_TOP       = '../src/optohybrid_top.vhd'


def main():

    MARKER_START = '    -- START: Station Specific Ports DO NOT EDIT --'
    MARKER_END   = '    -- END: Station Specific Ports DO NOT EDIT --'

    insert_code (OH_TOP, OH_TOP, MARKER_START, MARKER_END, write_oh_ports)

    MARKER_START = '    -- START: Station Specific Signals DO NOT EDIT --'
    MARKER_END   = '    -- END: Station Specific Signals DO NOT EDIT --'

    insert_code (OH_TOP, OH_TOP, MARKER_START, MARKER_END, write_oh_signals)

    MARKER_START = '    -- START: Station Specific IO DO NOT EDIT --'
    MARKER_END   = '    -- END: Station Specific IO DO NOT EDIT --'

    insert_code (OH_TOP, OH_TOP, MARKER_START, MARKER_END, write_oh_io)


def write_oh_ports (file_handle):

    f = file_handle

    ################################################################################
    # Trigger Units
    ################################################################################

    padding = "    " #spaces for indentation

    if (gem_version=="ge21"):
        master_slave_cnt = 6
        if (oh_version == "v1"):
            f.write ('%sgbt_txvalid_o  : out    std_logic_vector (MXREADY-1 downto 0);\n'             %  (padding))
            f.write ('%svtrx_mabs_i    : in    std_logic_vector (1 downto 0);\n'                      %  (padding))
            f.write ('\n');
            master_slave_cnt = 12
        elif (oh_version == "v2"):
#            f.write ('%selink_trig_o_p  : out    std_logic_vector (10 downto 0);\n'                   %  (padding))
#            f.write ('%selink_trig_o_n  : out    std_logic_vector (10 downto 0);\n'                   %  (padding))
            pass
        else:
            print "invalid GE2/1 OH version"
            return sys.exit(1)

        f.write ('%smaster_slave   : in     std_logic;\n'                                         %  (padding))
        f.write ('%smaster_slave_p : inout  std_logic_vector (%d downto 0);\n'                    %  (padding, master_slave_cnt - 1))
        f.write ('%smaster_slave_n : inout  std_logic_vector (%d downto 0);\n'                    %  (padding, master_slave_cnt - 1))
    elif (gem_version=="ge11"):
#       f.write ('%ssca_io      : in   std_logic_vector (3 downto 0); -- set as input for now\n'  %  (padding))
#       f.write ('%ssca_ctl     : in   std_logic_vector (2 downto 0);\n'                          %  (padding))
        f.write ('\n');
        f.write ('%sext_sbits_o : out  std_logic_vector (7 downto 0);\n'                          %  (padding))
        f.write ('\n');
        f.write ('%sext_reset_o : out  std_logic_vector (MXRESET-1 downto 0);\n'                  %  (padding))
        f.write ('\n');
        f.write ('%sadc_vp      : in   std_logic;\n'                                              %  (padding))
        f.write ('%sadc_vn      : in   std_logic;\n'                                              %  (padding))
    else:
        print "invalid GEM station"
        return sys.exit(1)

def write_oh_signals (file_handle):

    f = file_handle

    ################################################################################
    # Trigger Units
    ################################################################################

    padding = "    " #spaces for indentation

    if (gem_version=="ge21"):
        f.write('%s-- dummy signals for ge21\n' % padding)
        f.write('%ssignal ext_reset_o : std_logic_vector (11 downto 0);\n' % padding)
        f.write('%ssignal ext_sbits_o : std_logic_vector (7 downto 0);\n' % padding)
        f.write('%ssignal adc_vp      : std_logic;\n' % padding)
        f.write('%ssignal adc_vn      : std_logic;\n' % padding)
    elif (gem_version=="ge11"):
        f.write('\n')
    else:
        print "invalid GEM station"
        return sys.exit(1)

def write_oh_io (file_handle):

    f = file_handle

    ################################################################################
    # Trigger Units
    ################################################################################

    padding = "    " #spaces for indentation

    if (gem_version=="ge21"):
        if (oh_version=="v1"):
            f.write('%s--=============--\n' % padding)
            f.write('%s--== GE21 v1 ==--\n' % padding)
            f.write('%s--=============--\n' % padding)

            f.write('%sgbt_txvalid_o <= "11";\n' % padding)
            f.write('%svtrx_mabs    <= vtrx_mabs_i;\n' % padding)
        elif (oh_version == "v2"):
            f.write('%s--=============--\n' % padding)
            f.write('%s--== GE21 v2 ==--\n' % padding)
            f.write('%s--=============--\n' % padding)

            f.write("%svtrx_mabs    <= (others => '0');\n" % padding)
        else:
            print "invalid GE2/1 OH version"
            return sys.exit(1)
            
    elif (gem_version=="ge11"):
        f.write('%s--===========--\n' % padding)
        f.write('%s--== GE11  ==--\n' % padding)
        f.write('%s--===========--\n' % padding)

        f.write('%sext_reset_o  <= ctrl_reset_vfats;\n' % padding)
        f.write('%sext_sbits_o  <= ext_sbits;\n' % padding)
    else:
        print "invalid GEM station"
        return sys.exit(1)

if __name__ == '__main__':
    main()
