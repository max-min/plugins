
do

    local ps_proto = Proto("PSOverTCP", "PS stream Over Tcp protolcol")

    local tcplen = ProtoField.uint32("PSOverTCP.tcplen", "tcpLength", base.DEC)
    local psheader = ProtoField.uint32("PSOverTCP.psheader", "Header[ps]", base.HEX)
    local pscontent = ProtoField.bytes("PSOverTCP.pscontent", "Content[ps]", base.NONE)
    
    local sysheader = ProtoField.uint32("PSOverTCP.sysheader", "Header[system]", base.HEX)
    local syslen = ProtoField.uint32("PSOverTCP.syslen", "Lenght[system]", base.DEC)
    local syscontent = ProtoField.bytes("PSOverTCP.syscontent", "Content[system]", base.NONE)

    local mapheader = ProtoField.uint32("PSOverTCP.mapheader", "Header[systemmap]", base.HEX)
    local maplen = ProtoField.uint32("PSOverTCP.maplen", "Length[systemmap]", base.DEC)
    local mapcontent = ProtoField.bytes("PSOverTCP.mapcontent","Content[systemmap]", base.NONE)

    local pesheader = ProtoField.uint32("PSOverTCP.pesheader", "Header[pes]", base.HEX)
    local peslen = ProtoField.uint32("PSOverTCP.pesheader", "Lenght[pes]", base.DEC)
    local pescontent = ProtoField.bytes("PSOverTCP.pescontent", "Content[pes]", base.NONE)
    local pesheaderlen = ProtoField.uint32("PSOverTCP.pesheaderlen", "Length[pes]", base.DEC)

    local payloadlen = ProtoField.uint32("PSOverTCP.payloadlength", "Lenght[payload]", base.DEC)
    local datapayload = ProtoField.bytes("PSOverTCP.datapayload", "Payload", base.NODE)

    ps_proto.fields = {
        tcplen,
        psheader,
        pscontent,
        sysheader,
        syslen,
        syscontent,
        mapheader,
        maplen,
        mapcontent,
        pesheader,
        peslen,
        pescontent,
        pesheaderlen,
        payloadlen,
        datapayload
    }
    

    function ps_proto.dissector(tvb, pinfo, tree)
        
        pinfo.cols.protocol:set(ps_proto.name)
        pinfo.cols.info:set("PS Stream Over Tcp")
        
        local offset = 0
        local tvb_len = tvb:len()
        
        local ps_tree = tree:add(ps_proto,  tvb:range(offset, tvb_len)) 


        local rtp_type_1 = tvb(2, 1):uint()
        local rtp_type_2 = tvb(3, 1):uint()
       
        if (rtp_type_1 == 0x80 and rtp_type_2 == 0x60) then 
           
            local tcplen = tvb(offset, 2):uint()
            
            ps_tree:add(tcplen, tvb:range(offset, tcplen))
            offset = offset +2  
            -- rtp header 
            offset = offset + 12

            local ps_type = tvb(offset, 4):uint()
            if (ps_type == 0x000001ba)
            then 
                ps_tree:add(psheader, tvb:range(offset,  4))
                offset = offset+4        
                ps_tree:add(pscontent,tvb:range(offset,  16))
                offset = offset+16
            end 
           
    
            local sys_type = tvb(offset, 4):uint()
            if (sys_type == 0x000001bb)
            then 
                ps_tree:add(sysheader,tvb:range(offset,  4))
                offset = offset+4
                ps_tree:add(syslen,tvb:range(offset, 2))
                local lens = tvb(offset, 2):uint()
                offset = offset+2
    
                ps_tree:add(syscontent, tvb:range(offset, lens))
                offset = offset + lens
            end 
    
    
            local map_type = tvb(offset, 4):uint()
            if (map_type == 0x000001bc) 
            then 
                ps_tree:add(mapheader, tvb:range(offset,4))
                offset = offset + 4
                ps_tree:add(maplen, tvb:range(offset,2))
                local lens2 = tvb(offset, 2):uint()
                offset = offset + 2
                ps_tree:add(mapcontent, tvb:range(offset,lens2))
                offset = offset + lens2
            end 
    
            while( offset < tvb:len())
            do
                local pes_type = tvb(offset, 4):uint()
                if (pes_type == 0x000001e0 or pes_type == 0x000001c0)
                then 
                    ps_tree:add(pesheader, tvb:range(offset,4))
                    offset = offset + 4
                    ps_tree:add(peslen, tvb:range(offset,2))
                    local lens3 = tvb(offset, 2):uint()
                    offset = offset +2 
                    
    
                    offset = offset + 2
                    ps_tree:add(pesheaderlen, tvb:range(offset,1))
                    local peslens = tvb(offset,1):uint()
                    offset = offset +1
    
                    ps_tree:add(pescontent, tvb:range(offset,peslens))
                    offset = offset + peslens
                    local payloadlens = lens3 - (peslens+3)
                    
    
                    if payloadlens > tvb:len() 
                    then 
                        ps_tree:add(datapayload, tvb:range(offset,tvb:len()- offset))
                        offset = tvb:len()
                    else 
                        ps_tree:add(datapayload, tvb:range(offset,payloadlens))
                        offset = offset + payloadlens
                    end   
                else 
                    ps_tree:add(datapayload, tvb:range(offset,tcplen-12))
                    offset = tvb:len()
                end 
            end 
        else 
            ps_tree:add(datapayload, tvb:range(0, tvb_len))
            offset = tvb_len
            return
        end

 
       
    end
    
    local udp_port_table = DissectorTable.get("tcp.port")
    udp_port_table:add(41185, ps_proto)


end
   
